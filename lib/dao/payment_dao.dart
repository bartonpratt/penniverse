import 'dart:async';
import 'package:penniverse/dao/account_dao.dart';
import 'package:penniverse/dao/category_dao.dart';
import 'package:penniverse/helpers/db.helper.dart';
import 'package:penniverse/model/account.model.dart';
import 'package:penniverse/model/category.model.dart';
import 'package:penniverse/model/payment.model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PaymentDao {
  Future<int> create(Payment payment) async {
    final db = await getDBInstance();
    return await db.transaction((txn) async {
      var result = await txn.insert("payments", payment.toJson());
      return result;
    });
  }

  Future<List<Payment>> find({
    DateTimeRange? range,
    PaymentType? type,
    Category? category,
    Account? account,
    int? limit,
    int? offset,
    String? receiptPath, // Added parameter for receipt image path
  }) async {
    final db = await getDBInstance();
    String where = "";

    if (range != null) {
      where += "AND datetime BETWEEN DATE('${DateFormat('yyyy-MM-dd kk:mm:ss').format(range.start)}') AND DATE('${DateFormat('yyyy-MM-dd kk:mm:ss').format(range.end.add(const Duration(days: 1)))}')";
    }

    if (type != null) {
      where += "AND type='${type == PaymentType.credit ? "CR" : "DR"}' ";
    }

    if (account != null) {
      where += "AND account='${account.id}' ";
    }

    if (category != null) {
      where += "AND category='${category.id}' ";
    }

    if (receiptPath != null) { // Condition to filter by receipt image path
      where += "AND receiptPath='$receiptPath' ";
    }

    List<Category> categories = await CategoryDao().find();
    List<Account> accounts = await AccountDao().find();

    List<Payment> payments = [];
    List<Map<String, Object?>> rows = await db.query(
      "payments",
      orderBy: "datetime DESC, id DESC",
      where: "1=1 $where",
      limit: limit,
      offset: offset,
    );
    for (var row in rows) {
      Map<String, dynamic> payment = Map<String, dynamic>.from(row);
      Account account = accounts.firstWhere((a) => a.id == payment["account"]);
      Category category = categories.firstWhere((c) => c.id == payment["category"]);
      payment["category"] = category.toJson();
      payment["account"] = account.toJson();
      payments.add(Payment.fromJson(payment));
    }

    return payments;
  }

  Future<int> count({
    DateTimeRange? range,
    PaymentType? type,
    Category? category,
    Account? account,
    String? receiptPath, // Added parameter for receipt image path
    int? limit,
    int? offset,
  }) async {
    final db = await getDBInstance();
    String where = "";

    if (range != null) {
      where += "AND datetime BETWEEN DATE('${DateFormat('yyyy-MM-dd kk:mm:ss').format(range.start)}') AND DATE('${DateFormat('yyyy-MM-dd kk:mm:ss').format(range.end.add(const Duration(days: 1)))}')";
    }

    if (type != null) {
      where += "AND type='${type == PaymentType.credit ? "CR" : "DR"}' ";
    }

    if (account != null) {
      where += "AND account='${account.id}' ";
    }

    if (category != null) {
      where += "AND category='${category.id}' ";
    }

    if (receiptPath != null) { // Condition to filter by receipt image path
      where += "AND receiptPath='$receiptPath' ";
    }

    List<Map<String, Object?>> rows = await db.query(
      "payments",
      where: "1=1 $where",
      limit: limit,
      offset: offset,
      columns: ["count(*) as count"],
    );
    return (rows[0]["count"] as int?) ?? 0;
  }

  Future<int> update(Payment payment) async {
    final db = await getDBInstance();
    var result = await db.update("payments", payment.toJson(), where: "id = ?", whereArgs: [payment.id]);
    return result;
  }

  Future<int> upsert(Payment payment) async {
    final db = await getDBInstance();
    int result;
    if (payment.id != null) {
      result = await db.update(
        "payments",
        payment.toJson(),
        where: "id = ?",
        whereArgs: [payment.id],
      );
    } else {
      result = await db.insert("payments", payment.toJson());
    }

    return result;
  }

  Future<int> deleteTransaction(int id) async {
    final db = await getDBInstance();
    var result = await db.delete("payments", where: 'id = ?', whereArgs: [id]);
    return result;
  }

  Future deleteAllTransactions() async {
    final db = await getDBInstance();
    var result = await db.delete("payments");
    return result;

  }
}

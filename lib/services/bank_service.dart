import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/bank.dart';

class BankService {
  static final BankService _instance = BankService._internal();
  List<Bank>? _banks;

  factory BankService() {
    return _instance;
  }

  BankService._internal();

  Future<List<Bank>> getBanks() async {
    if (_banks != null) {
      return _banks!;
    }

    try {
      final jsonString = await rootBundle.loadString('assets/bank_list.json');
      final jsonData = jsonDecode(jsonString);
      final bankList = (jsonData['data'] as List)
          .map((e) => Bank.fromJson(e as Map<String, dynamic>))
          .toList();
      _banks = bankList;
      return bankList;
    } catch (e) {
      throw Exception('Failed to load banks: $e');
    }
  }

  Bank? getBankByCode(String kodeBank) {
    if (_banks == null) return null;
    try {
      return _banks!.firstWhere((bank) => bank.kodeBank == kodeBank);
    } catch (e) {
      return null;
    }
  }

  Future<Bank?> getBankByCodeAsync(String kodeBank) async {
    final banks = await getBanks();
    try {
      return banks.firstWhere((bank) => bank.kodeBank == kodeBank);
    } catch (e) {
      return null;
    }
  }
}

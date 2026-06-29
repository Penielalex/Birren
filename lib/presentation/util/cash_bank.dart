import '../../domain/entities/bank.dart';

const String cashBankName = 'Cash';

bool isCashBankName(String bankName) => bankName == cashBankName;

bool isCashBank(Bank bank) => isCashBankName(bank.bankName);

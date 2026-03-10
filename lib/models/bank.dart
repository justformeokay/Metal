class Bank {
  final String kodeBank;
  final String? bankId;
  final String namaBank;
  final String? urlImage;

  Bank({
    required this.kodeBank,
    this.bankId,
    required this.namaBank,
    this.urlImage,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      kodeBank: json['kode_bank'] ?? '',
      bankId: json['bank_id'],
      namaBank: json['nama_bank'] ?? '',
      urlImage: json['url_image'],
    );
  }

  Map<String, dynamic> toJson() => {
    'kode_bank': kodeBank,
    'bank_id': bankId,
    'nama_bank': namaBank,
    'url_image': urlImage,
  };

  @override
  String toString() => namaBank;
}

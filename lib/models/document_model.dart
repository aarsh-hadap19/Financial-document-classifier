class DocumentModel {
  final String id;
  final String name;
  final String path;
  final String? classification;
  final DateTime uploadDate;
  final bool isProcessing;

  DocumentModel({
    required this.id,
    required this.name,
    required this.path,
    this.classification,
    required this.uploadDate,
    this.isProcessing = false,
  });

  DocumentModel copyWith({
    String? id,
    String? name,
    String? path,
    String? classification,
    DateTime? uploadDate,
    bool? isProcessing,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      classification: classification ?? this.classification,
      uploadDate: uploadDate ?? this.uploadDate,
      isProcessing: isProcessing ?? this.isProcessing,
    );
  }
}


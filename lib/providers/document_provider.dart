import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../services/document_service.dart';

class DocumentProvider extends ChangeNotifier {
  final List<DocumentModel> _documents = [];
  bool _isUploading = false;
  String? _error;

  List<DocumentModel> get documents => _documents;
  bool get isUploading => _isUploading;
  String? get error => _error;

  final DocumentService _documentService = DocumentService();

  Future<void> uploadDocument(String filePath, String fileName) async {
    _isUploading = true;
    _error = null;
    notifyListeners();

    try {
      final document = DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: filePath,
        uploadDate: DateTime.now(),
        isProcessing: true,
      );

      _documents.insert(0, document);
      notifyListeners();

      final classification = await _documentService.classifyDocument(filePath);

      final index = _documents.indexWhere((doc) => doc.id == document.id);
      if (index != -1) {
        _documents[index] = document.copyWith(
          classification: classification,
          isProcessing: false,
        );
      }

      _isUploading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isUploading = false;

      // Remove the document if classification failed
      _documents.removeWhere((doc) => doc.path == filePath);
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void removeDocument(String id) {
    _documents.removeWhere((doc) => doc.id == id);
    notifyListeners();
  }
}

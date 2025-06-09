import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  void setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void addDocument(DocumentModel document) {
    _documents.insert(0, document);
    notifyListeners();
  }

  void updateDocument(DocumentModel updatedDocument) {
    final index = _documents.indexWhere((doc) => doc.id == updatedDocument.id);
    if (index != -1) {
      _documents[index] = updatedDocument;
      notifyListeners();
    }
  }

  // Test backend connection
  Future<void> testBackendConnection() async {
    try {
      final status = await _documentService.checkServerStatus();
      if (kDebugMode) {
        print('Backend status: $status');
      }

      // Also test the classify endpoint directly
      final testResponse = await http.get(
        Uri.parse('${DocumentService.baseUrl}/classify'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (kDebugMode) {
        print('Classify endpoint status: ${testResponse.statusCode}');
        print('Classify endpoint response: ${testResponse.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Backend connection test failed: $e');
      }
    }
  }

  // Enhanced upload method with better error handling and debugging
  Future<void> uploadDocument(String filePath, String fileName) async {
    setUploading(true);
    clearError();

    try {
      if (kDebugMode) {
        print('Starting upload process for: $fileName');
        print('File path: $filePath');
      }

      // Test connection first
      final isConnected = await _documentService.testConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to server. Please check if your backend is running on ${DocumentService.baseUrl}');
      }

      if (kDebugMode) {
        print('Backend connection successful');
      }

      // Create document with processing state
      final document = DocumentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: fileName,
        path: filePath,
        uploadDate: DateTime.now(),
        isProcessing: true,
      );

      addDocument(document);

      if (kDebugMode) {
        print('Document added to list, starting classification...');
      }

      // Classify document
      final classification = await _documentService.classifyDocument(filePath);

      if (kDebugMode) {
        print('Classification completed: $classification');
      }

      // Update document with classification
      final updatedDocument = document.copyWith(
        classification: classification,
        isProcessing: false,
      );

      updateDocument(updatedDocument);

      if (kDebugMode) {
        print('Document updated with classification result');
      }

    } catch (e) {
      if (kDebugMode) {
        print('Upload/Classification error: $e');
      }

      setError(e.toString());

      // Remove the document if it was added but failed
      if (_documents.any((doc) => doc.path == filePath)) {
        _documents.removeWhere((doc) => doc.path == filePath);
        notifyListeners();
      }
    } finally {
      setUploading(false);
    }
  }

  // Upload multiple documents
  Future<void> uploadMultipleDocuments(List<String> filePaths, List<String> fileNames) async {
    if (filePaths.length != fileNames.length) {
      setError('File paths and names count mismatch');
      return;
    }

    setUploading(true);
    clearError();

    int successCount = 0;
    int failCount = 0;
    String lastError = '';

    try {
      // Test connection once before starting batch upload
      final isConnected = await _documentService.testConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to server. Please check if your backend is running.');
      }

      for (int i = 0; i < filePaths.length; i++) {
        try {
          final filePath = filePaths[i];
          final fileName = fileNames[i];

          if (kDebugMode) {
            print('Processing file ${i + 1}/${filePaths.length}: $fileName');
          }

          // Create document with processing state
          final document = DocumentModel(
            id: '${DateTime.now().millisecondsSinceEpoch}_$i',
            name: fileName,
            path: filePath,
            uploadDate: DateTime.now(),
            isProcessing: true,
          );

          addDocument(document);

          // Classify document
          final classification = await _documentService.classifyDocument(filePath);

          // Update document with classification
          final updatedDocument = document.copyWith(
            classification: classification,
            isProcessing: false,
          );

          updateDocument(updatedDocument);
          successCount++;

        } catch (e) {
          failCount++;
          lastError = e.toString();

          if (kDebugMode) {
            print('Failed to process ${fileNames[i]}: $e');
          }

          // Remove failed document from list
          _documents.removeWhere((doc) => doc.path == filePaths[i]);
          notifyListeners();
        }
      }

      // Set appropriate error message for batch results
      if (failCount > 0) {
        if (successCount > 0) {
          setError('$successCount file(s) processed successfully, $failCount failed. Last error: $lastError');
        } else {
          setError('All files failed to process. Error: $lastError');
        }
      }

    } catch (e) {
      setError(e.toString());
    } finally {
      setUploading(false);
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

  // Clear all documents
  void clearAllDocuments() {
    _documents.clear();
    notifyListeners();
  }

  // Get documents by classification
  List<DocumentModel> getDocumentsByClassification(String classification) {
    return _documents.where((doc) => doc.classification == classification).toList();
  }

  // Get processing documents count
  int get processingCount => _documents.where((doc) => doc.isProcessing).length;

  // Get classified documents count
  int get classifiedCount => _documents.where((doc) => doc.classification != null && !doc.isProcessing).length;

  // Get unique classifications
  List<String> get uniqueClassifications {
    final classifications = _documents
        .where((doc) => doc.classification != null && doc.classification!.isNotEmpty)
        .map((doc) => doc.classification!)
        .toSet()
        .toList();
    classifications.sort();
    return classifications;
  }

  // Retry classification for a specific document
  Future<void> retryClassification(String documentId) async {
    final documentIndex = _documents.indexWhere((doc) => doc.id == documentId);
    if (documentIndex == -1) return;

    final document = _documents[documentIndex];

    try {
      // Update document to processing state
      _documents[documentIndex] = document.copyWith(
        isProcessing: true,
        classification: null,
      );
      notifyListeners();

      // Retry classification
      final classification = await _documentService.classifyDocument(document.path);

      // Update with new classification
      _documents[documentIndex] = document.copyWith(
        classification: classification,
        isProcessing: false,
      );
      notifyListeners();

    } catch (e) {
      // Revert to original state on failure
      _documents[documentIndex] = document.copyWith(
        isProcessing: false,
      );
      setError('Failed to retry classification: $e');
    }
  }

  @override
  void dispose() {
    _documents.clear();
    super.dispose();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:quenc/models/Comment.dart';

class CommentService with ChangeNotifier {
  final Firestore _db = Firestore.instance;
  final int _pageSize = 50;

  Future<List<Comment>> getCommentForPost(String postId) async {
    List<Comment> retrivedComments = [];
    var docs = await _db
        .collection("comments")
        .where("belongPost", isEqualTo: postId)
        .getDocuments();

    for (DocumentSnapshot d in docs.documents) {
      retrivedComments.add(Comment.fromMap(d.data));
    }

    return retrivedComments;
  }

  Future<String> addComment(Comment comment) async {
    var ref = _db.collection("comments").document();
    comment.id = ref.documentID;
    await ref.setData(comment.toMap());

    return ref.documentID;
  }

  Future<String> updateComment(
      String commentId, Map<String, dynamic> updateFields) {
    DocumentReference ref = _db.collection("comments").document(commentId);
    return ref.setData(updateFields, merge: true);
  }

  
}

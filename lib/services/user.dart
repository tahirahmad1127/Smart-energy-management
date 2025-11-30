
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:news_app/models/user.dart';

class UserServices{
  ///create user
  Future createUser(User model) async{
    return await FirebaseFirestore.instance
        .collection('userCollection')
        .doc(model.docId)
        .set(model.toJson());
  }
}
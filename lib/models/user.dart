// To parse this JSON data, do
//
//     final user = userFromJson(jsonString);

import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  final String? name;
  final String? email;
  final int? createdAt;
  final String? phone;
  final String? address;
  final String? image;
  final String? docId;

  User({
    this.name,
    this.email,
    this.createdAt,
    this.phone,
    this.address,
    this.image,
    this.docId,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    name: json["name"],
    email: json["email"],
    createdAt: json["createdAt"],
    phone: json["phone"],
    address: json["address"],
    image: json["image"],
    docId: json["docId"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "email": email,
    "createdAt": createdAt,
    "phone": phone,
    "address": address,
    "image": image,
    "docId": docId,
  };
}

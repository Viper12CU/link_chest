import 'package:flutter/material.dart';
import 'package:link_chest/database/models/category_model.dart';

String _now() => DateTime.now().toUtc().toIso8601String();

final List<CategoryModel> categorysDebug = [
  CategoryModel(
    userId: 'debug',
    title: "Cohete",
    icon: "🚀",
    color: Colors.amber.toString(),
    createdAt: _now(),
    updatedAt: _now(),
  ),
  CategoryModel(
    userId: 'debug',
    title: "Auto",
    icon: "🚗",
    color: Colors.redAccent.toString(),
    createdAt: _now(),
    updatedAt: _now(),
  ),
  CategoryModel(
    userId: 'debug',
    title: "Moto",
    icon: "🏍️",
    color: Colors.lightBlue.toString(),
    createdAt: _now(),
    updatedAt: _now(),
  ),
  CategoryModel(
    userId: 'debug',
    title: "Bus",
    icon: "🚌",
    color: Colors.green.toString(),
    createdAt: _now(),
    updatedAt: _now(),
  ),
];

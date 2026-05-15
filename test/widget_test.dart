// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:tindatap/main.dart';
import 'package:tindatap/providers/cart_provider.dart';
import 'package:tindatap/providers/product_provider.dart';
import 'package:tindatap/providers/settings_provider.dart';
import 'package:tindatap/providers/transaction_provider.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ],
        child: const TindaTapApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

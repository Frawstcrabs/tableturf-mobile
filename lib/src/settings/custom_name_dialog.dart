// Copyright 2022, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'settings.dart';

Future<String> showCustomNameDialog(BuildContext context, String name, {String? title, int? maxLength}) async {
  final ret = await showGeneralDialog<String>(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return CustomNameDialog(
        animation: animation,
        value: name,
        title: title,
        maxLength: maxLength,
      );
    }
  );
  return ret!;
}

class CustomNameDialog extends StatefulWidget {
  final Animation<double> animation;
  final String value;
  final String? title;
  final int? maxLength;

  const CustomNameDialog({
    super.key,
    required this.animation,
    required this.value,
    this.title,
    this.maxLength,
  });

  @override
  State<CustomNameDialog> createState() => _CustomNameDialogState();
}

class _CustomNameDialogState extends State<CustomNameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  void onExit() {
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: widget.animation,
        curve: Curves.easeOutCubic,
      ),
      child: SimpleDialog(
        title: Text(widget.title ?? 'Change name'),
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: widget.maxLength,
            maxLengthEnforcement: MaxLengthEnforcement.enforced,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              onExit();
            },
          ),
          TextButton(
            onPressed: onExit,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

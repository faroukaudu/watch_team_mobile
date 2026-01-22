import 'dart:io';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';
import 'package:flutter/material.dart';

class GalleryPickerService {
  Future<List<File>> pickImagesMax5(BuildContext context) async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 5,
        requestType: RequestType.image,
      ),
    );
    if (assets == null) return [];

    final files = <File>[];
    for (final a in assets) {
      final f = await a.file;
      if (f != null) files.add(f);
    }
    return files;
  }

  Future<File?> pickSingleVideo(BuildContext context) async {
    final List<AssetEntity>? assets = await AssetPicker.pickAssets(
      context,
      pickerConfig: const AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.video,
      ),
    );
    if (assets == null || assets.isEmpty) return null;
    return await assets.first.file;
  }
}

# G Lens

## Introduction

Bằng cách sử dụng annotation `@lens` để tạo ra lens cho một class, ta có thể truy cập các thuộc tính của class một cách dễ dàng hơn.

## Installation

```yaml
dependencies:
  g_lens:
    git:
      url: `link to g_lens`
      ref: `commit hash`


dev_dependencies:
  build_runner: `latest version`
  g_lens_generator:
    git:
      url: `link to g_lens_generator`
      ref: `commit hash`
```

## Usage

```dart
import 'package:g_lens/g_lens.dart';
part 'test_lens_generator.lens.dart';

@lens
class LensTest with _LensTestLens {
  final String name;
  final String type;
  final String value;
  final String id;

  LensTest(
    this.id, {
    required this.name,
    required this.type,
    required this.value,
  });

  factory LensTest.fromJson(Map<String, dynamic> json) {
    return LensTest(
      json['id'],
      name: json['name'],
      type: json['type'],
      value: json['value'],
    );
  }
}
```

Tạo một class với annotation `@lens` và sử dụng `part 'file_name.lens.dart'` kèm theo đó là sử dụng class với mixin `_{class_name}Lens` để tạo ra lens cho class đó.

Sau đó chạy lệnh
```zsh
dart run build_runner build --delete-conflicting-outputs
```
hoặc (makefile)
```zsh
make gen
```

Đây là file được tạo ra sau khi chạy câu lệnh trên:

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_lens_generator.dart';

// **************************************************************************
// LensGenerator
// **************************************************************************

// ignore_for_file: unused_field

mixin _LensTestLens {
  static final Lens<LensTest, String> idLens = Lens(
    getter: (whole) => whole.id,
    setter: (whole, partValue) => whole.copyWith(id: partValue),
  );
  static final Lens<LensTest, String> nameLens = Lens(
    getter: (whole) => whole.name,
    setter: (whole, partValue) => whole.copyWith(name: partValue),
  );
  static final Lens<LensTest, String> typeLens = Lens(
    getter: (whole) => whole.type,
    setter: (whole, partValue) => whole.copyWith(type: partValue),
  );
  static final Lens<LensTest, String> valueLens = Lens(
    getter: (whole) => whole.value,
    setter: (whole, partValue) => whole.copyWith(value: partValue),
  );
}

extension LensTestCopyWith on LensTest {
  LensTest copyWith({
    String? id,
    String? name,
    String? type,
    String? value,
  }) =>
      LensTest(
        id ?? this.id,
        name: name ?? this.name,
        type: type ?? this.type,
        value: value ?? this.value,
      );
}

```
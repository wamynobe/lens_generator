// https://github.com/ekmett/lens
// https://sinusoid.es/misc/lager/lenses.pdf - Lenses in Functional Programming
// https://github.com/spebbe/dartz/blob/master/lib/src/lens.dart
// https://github.com/kickstarter/Kickstarter-Prelude/blob/master/Sources/Prelude/Lens.swift

typedef KeyPath = Lens;

class Lens<Whole, Part> {
  // NOTE: Chú ý setter thứ tự Whole trước Part
  final Part Function(Whole whole) getter;
  final Whole Function(Whole whole, Part partValue) setter;

  Lens({
    required this.getter,
    required this.setter,
  });

  /// `Lens<A, B>` kết hợp với `Lens<B, C>` thành `Lens<A, C>`
  Lens<Whole, Subpart> compose<Subpart>(Lens<Part, Subpart> rhs) {
    return Lens<Whole, Subpart>(
      getter: (whole) => rhs.getter(this.getter(whole)),
      setter: (whole, subPart) {
        final part = this.getter(whole);
        final newPart = rhs.setter(part, subPart);
        return this.setter(whole, newPart);
      },
    );
  }

  // typedef
  Lens<Whole, Subpart> x<Subpart>(Lens<Part, Subpart> rhs) => compose(rhs);

  /// Map dữ liệu part thành giá trị mới, dựa trên part cũ
  Whole Function(Whole whole) over(Part Function(Part part) partMapper) {
    return (Whole x) {
      final part = this.getter(x);
      final newPart = partMapper(part);
      return this.setter(x, newPart);
    };
  }

  /// Map dữ liệu part thành giá trị mới, dựa trên cả part và whole cũ
  Whole Function(Whole whole) overCombine(
      Part Function(Whole whole, Part part) partCombinator) {
    return (Whole x) {
      final part = this.getter(x);
      final newPart = partCombinator(x, part);
      return this.setter(x, newPart);
    };
  }
}

// MARK: Helpers
// NOTE: Chú ý nếu runtimeType của Lens và Part lệch nhau, dart sẽ tự hiểu Part type thành `Object?` và sẽ bị lỗi kiểu dữ liệu khi gọi hàm Lens.setter
// NOTE: dart ko cho định nghĩa operator nên tạm là các hàm này
Part lensGetter<Whole, Part>(
  Whole whole,
  Lens<Whole, Part> lens,
) {
  return lens.getter(whole);
}

Whole Function(Whole whole) lensSetter<Whole, Part>(
  Lens<Whole, Part> lens,
  Part newValue,
) {
  return (Whole x) => lens.setter(x, newValue);
}

Lens<Whole, Subpart> lensCompose<Whole, Part, Subpart>(
    Lens<Whole, Part> lhs, Lens<Part, Subpart> rhs) {
  return lhs.compose(rhs);
}

Whole Function(Whole whole) lensOver<Whole, Part>(
  Lens<Whole, Part> lens,
  Part Function(Part part) partMapper,
) {
  return lens.over(partMapper);
}

Whole Function(Whole whole) lensOverCombine<Whole, Part>(
  Lens<Whole, Part> lens,
  Part Function(Whole whole, Part part) partCombinator,
) {
  return lens.overCombine(partCombinator);
}

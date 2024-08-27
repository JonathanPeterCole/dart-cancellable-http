// Autogenerated by jnigen. DO NOT EDIT!

// ignore_for_file: annotate_overrides
// ignore_for_file: camel_case_extensions
// ignore_for_file: camel_case_types
// ignore_for_file: constant_identifier_names
// ignore_for_file: file_names
// ignore_for_file: no_leading_underscores_for_local_identifiers
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: overridden_fields
// ignore_for_file: unnecessary_cast
// ignore_for_file: unused_element
// ignore_for_file: unused_field
// ignore_for_file: unused_import
// ignore_for_file: unused_shown_name

import "dart:isolate" show ReceivePort;
import "dart:ffi" as ffi;
import "package:jni/internal_helpers_for_jnigen.dart";
import "package:jni/jni.dart" as jni;

import "OutputStream.dart" as outputstream_;

/// from: java.io.InputStream
class InputStream extends jni.JObject {
  @override
  late final jni.JObjType<InputStream> $type = type;

  InputStream.fromRef(
    jni.JObjectPtr ref,
  ) : super.fromRef(ref);

  static final _class = jni.Jni.findJClass(r"java/io/InputStream");

  /// The type which includes information such as the signature of this class.
  static const type = $InputStreamType();
  static final _id_ctor =
      jni.Jni.accessors.getMethodIDOf(_class.reference, r"<init>", r"()V");

  /// from: public void <init>()
  /// The returned object must be deleted after use, by calling the `delete` method.
  factory InputStream() {
    return InputStream.fromRef(jni.Jni.accessors
        .newObjectWithArgs(_class.reference, _id_ctor, []).object);
  }

  static final _id_nullInputStream = jni.Jni.accessors.getStaticMethodIDOf(
      _class.reference, r"nullInputStream", r"()Ljava/io/InputStream;");

  /// from: static public java.io.InputStream nullInputStream()
  /// The returned object must be deleted after use, by calling the `delete` method.
  static InputStream nullInputStream() {
    return const $InputStreamType().fromRef(jni.Jni.accessors
        .callStaticMethodWithArgs(_class.reference, _id_nullInputStream,
            jni.JniCallType.objectType, []).object);
  }

  static final _id_read =
      jni.Jni.accessors.getMethodIDOf(_class.reference, r"read", r"()I");

  /// from: public abstract int read()
  int read() {
    return jni.Jni.accessors.callMethodWithArgs(
        reference, _id_read, jni.JniCallType.intType, []).integer;
  }

  static final _id_read1 =
      jni.Jni.accessors.getMethodIDOf(_class.reference, r"read", r"([B)I");

  /// from: public int read(byte[] bs)
  int read1(
    jni.JArray<jni.jbyte> bs,
  ) {
    return jni.Jni.accessors.callMethodWithArgs(
        reference, _id_read1, jni.JniCallType.intType, [bs.reference]).integer;
  }

  static final _id_read2 =
      jni.Jni.accessors.getMethodIDOf(_class.reference, r"read", r"([BII)I");

  /// from: public int read(byte[] bs, int i, int i1)
  int read2(
    jni.JArray<jni.jbyte> bs,
    int i,
    int i1,
  ) {
    return jni.Jni.accessors.callMethodWithArgs(
        reference,
        _id_read2,
        jni.JniCallType.intType,
        [bs.reference, jni.JValueInt(i), jni.JValueInt(i1)]).integer;
  }

  static final _id_readAllBytes = jni.Jni.accessors
      .getMethodIDOf(_class.reference, r"readAllBytes", r"()[B");

  /// from: public byte[] readAllBytes()
  /// The returned object must be deleted after use, by calling the `delete` method.
  jni.JArray<jni.jbyte> readAllBytes() {
    return const jni.JArrayType(jni.jbyteType()).fromRef(jni.Jni.accessors
        .callMethodWithArgs(reference, _id_readAllBytes,
            jni.JniCallType.objectType, []).object);
  }

  static final _id_readNBytes = jni.Jni.accessors
      .getMethodIDOf(_class.reference, r"readNBytes", r"(I)[B");

  /// from: public byte[] readNBytes(int i)
  /// The returned object must be deleted after use, by calling the `delete` method.
  jni.JArray<jni.jbyte> readNBytes(
    int i,
  ) {
    return const jni.JArrayType(jni.jbyteType()).fromRef(jni.Jni.accessors
        .callMethodWithArgs(reference, _id_readNBytes,
            jni.JniCallType.objectType, [jni.JValueInt(i)]).object);
  }

  static final _id_readNBytes1 = jni.Jni.accessors
      .getMethodIDOf(_class.reference, r"readNBytes", r"([BII)I");

  /// from: public int readNBytes(byte[] bs, int i, int i1)
  int readNBytes1(
    jni.JArray<jni.jbyte> bs,
    int i,
    int i1,
  ) {
    return jni.Jni.accessors.callMethodWithArgs(
        reference,
        _id_readNBytes1,
        jni.JniCallType.intType,
        [bs.reference, jni.JValueInt(i), jni.JValueInt(i1)]).integer;
  }

  static final _id_skip =
      jni.Jni.accessors.getMethodIDOf(_class.reference, r"skip", r"(J)J");

  /// from: public long skip(long j)
  int skip(
    int j,
  ) {
    return jni.Jni.accessors.callMethodWithArgs(
        reference, _id_skip, jni.JniCallType.longType, [j]).long;
  }

  static final _id_available =
      jni.Jni.accessors.getMethodIDOf(_class.reference, r"available", r"()I");

  /// from: public int available()
  int available() {
    return jni.Jni.accessors.callMethodWithArgs(
        reference, _id_available, jni.JniCallType.intType, []).integer;
  }

  static final _id_close =
      jni.Jni.accessors.getMethodIDOf(_class.reference, r"close", r"()V");

  /// from: public void close()
  void close() {
    return jni.Jni.accessors.callMethodWithArgs(
        reference, _id_close, jni.JniCallType.voidType, []).check();
  }

  static final _id_mark =
      jni.Jni.accessors.getMethodIDOf(_class.reference, r"mark", r"(I)V");

  /// from: public void mark(int i)
  void mark(
    int i,
  ) {
    return jni.Jni.accessors.callMethodWithArgs(reference, _id_mark,
        jni.JniCallType.voidType, [jni.JValueInt(i)]).check();
  }

  static final _id_reset =
      jni.Jni.accessors.getMethodIDOf(_class.reference, r"reset", r"()V");

  /// from: public void reset()
  void reset() {
    return jni.Jni.accessors.callMethodWithArgs(
        reference, _id_reset, jni.JniCallType.voidType, []).check();
  }

  static final _id_markSupported = jni.Jni.accessors
      .getMethodIDOf(_class.reference, r"markSupported", r"()Z");

  /// from: public boolean markSupported()
  bool markSupported() {
    return jni.Jni.accessors.callMethodWithArgs(
        reference, _id_markSupported, jni.JniCallType.booleanType, []).boolean;
  }

  static final _id_transferTo = jni.Jni.accessors.getMethodIDOf(
      _class.reference, r"transferTo", r"(Ljava/io/OutputStream;)J");

  /// from: public long transferTo(java.io.OutputStream outputStream)
  int transferTo(
    outputstream_.OutputStream outputStream,
  ) {
    return jni.Jni.accessors.callMethodWithArgs(reference, _id_transferTo,
        jni.JniCallType.longType, [outputStream.reference]).long;
  }
}

class $InputStreamType extends jni.JObjType<InputStream> {
  const $InputStreamType();

  @override
  String get signature => r"Ljava/io/InputStream;";

  @override
  InputStream fromRef(jni.JObjectPtr ref) => InputStream.fromRef(ref);

  @override
  jni.JObjType get superType => const jni.JObjectType();

  @override
  final superCount = 1;

  @override
  int get hashCode => ($InputStreamType).hashCode;

  @override
  bool operator ==(Object other) {
    return other.runtimeType == ($InputStreamType) && other is $InputStreamType;
  }
}

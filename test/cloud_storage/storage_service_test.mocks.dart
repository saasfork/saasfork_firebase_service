// Mocks generated by Mockito 5.4.5 from annotations
// in saasfork_firebase_service/test/cloud_storage/storage_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;
import 'dart:io' as _i8;
import 'dart:typed_data' as _i7;

import 'package:firebase_core/firebase_core.dart' as _i2;
import 'package:firebase_storage/firebase_storage.dart' as _i3;
import 'package:firebase_storage_platform_interface/firebase_storage_platform_interface.dart'
    as _i4;
import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i6;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeFirebaseApp_0 extends _i1.SmartFake implements _i2.FirebaseApp {
  _FakeFirebaseApp_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeDuration_1 extends _i1.SmartFake implements Duration {
  _FakeDuration_1(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeReference_2 extends _i1.SmartFake implements _i3.Reference {
  _FakeReference_2(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeFirebaseStorage_3 extends _i1.SmartFake
    implements _i3.FirebaseStorage {
  _FakeFirebaseStorage_3(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeFullMetadata_4 extends _i1.SmartFake implements _i4.FullMetadata {
  _FakeFullMetadata_4(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeListResult_5 extends _i1.SmartFake implements _i3.ListResult {
  _FakeListResult_5(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeUploadTask_6 extends _i1.SmartFake implements _i3.UploadTask {
  _FakeUploadTask_6(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeDownloadTask_7 extends _i1.SmartFake implements _i3.DownloadTask {
  _FakeDownloadTask_7(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeTaskSnapshot_8 extends _i1.SmartFake implements _i3.TaskSnapshot {
  _FakeTaskSnapshot_8(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeFuture_9<T> extends _i1.SmartFake implements _i5.Future<T> {
  _FakeFuture_9(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [FirebaseStorage].
///
/// See the documentation for Mockito's code generation for more information.
class MockFirebaseStorage extends _i1.Mock implements _i3.FirebaseStorage {
  MockFirebaseStorage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.FirebaseApp get app =>
      (super.noSuchMethod(
            Invocation.getter(#app),
            returnValue: _FakeFirebaseApp_0(this, Invocation.getter(#app)),
          )
          as _i2.FirebaseApp);

  @override
  set app(_i2.FirebaseApp? _app) => super.noSuchMethod(
    Invocation.setter(#app, _app),
    returnValueForMissingStub: null,
  );

  @override
  String get bucket =>
      (super.noSuchMethod(
            Invocation.getter(#bucket),
            returnValue: _i6.dummyValue<String>(
              this,
              Invocation.getter(#bucket),
            ),
          )
          as String);

  @override
  set bucket(String? _bucket) => super.noSuchMethod(
    Invocation.setter(#bucket, _bucket),
    returnValueForMissingStub: null,
  );

  @override
  Duration get maxOperationRetryTime =>
      (super.noSuchMethod(
            Invocation.getter(#maxOperationRetryTime),
            returnValue: _FakeDuration_1(
              this,
              Invocation.getter(#maxOperationRetryTime),
            ),
          )
          as Duration);

  @override
  Duration get maxUploadRetryTime =>
      (super.noSuchMethod(
            Invocation.getter(#maxUploadRetryTime),
            returnValue: _FakeDuration_1(
              this,
              Invocation.getter(#maxUploadRetryTime),
            ),
          )
          as Duration);

  @override
  Duration get maxDownloadRetryTime =>
      (super.noSuchMethod(
            Invocation.getter(#maxDownloadRetryTime),
            returnValue: _FakeDuration_1(
              this,
              Invocation.getter(#maxDownloadRetryTime),
            ),
          )
          as Duration);

  @override
  Map<dynamic, dynamic> get pluginConstants =>
      (super.noSuchMethod(
            Invocation.getter(#pluginConstants),
            returnValue: <dynamic, dynamic>{},
          )
          as Map<dynamic, dynamic>);

  @override
  _i3.Reference ref([String? path]) =>
      (super.noSuchMethod(
            Invocation.method(#ref, [path]),
            returnValue: _FakeReference_2(
              this,
              Invocation.method(#ref, [path]),
            ),
          )
          as _i3.Reference);

  @override
  _i3.Reference refFromURL(String? url) =>
      (super.noSuchMethod(
            Invocation.method(#refFromURL, [url]),
            returnValue: _FakeReference_2(
              this,
              Invocation.method(#refFromURL, [url]),
            ),
          )
          as _i3.Reference);

  @override
  void setMaxOperationRetryTime(Duration? time) => super.noSuchMethod(
    Invocation.method(#setMaxOperationRetryTime, [time]),
    returnValueForMissingStub: null,
  );

  @override
  void setMaxUploadRetryTime(Duration? time) => super.noSuchMethod(
    Invocation.method(#setMaxUploadRetryTime, [time]),
    returnValueForMissingStub: null,
  );

  @override
  void setMaxDownloadRetryTime(Duration? time) => super.noSuchMethod(
    Invocation.method(#setMaxDownloadRetryTime, [time]),
    returnValueForMissingStub: null,
  );

  @override
  _i5.Future<void> useStorageEmulator(
    String? host,
    int? port, {
    bool? automaticHostMapping = true,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #useStorageEmulator,
              [host, port],
              {#automaticHostMapping: automaticHostMapping},
            ),
            returnValue: _i5.Future<void>.value(),
            returnValueForMissingStub: _i5.Future<void>.value(),
          )
          as _i5.Future<void>);
}

/// A class which mocks [Reference].
///
/// See the documentation for Mockito's code generation for more information.
class MockReference extends _i1.Mock implements _i3.Reference {
  MockReference() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.FirebaseStorage get storage =>
      (super.noSuchMethod(
            Invocation.getter(#storage),
            returnValue: _FakeFirebaseStorage_3(
              this,
              Invocation.getter(#storage),
            ),
          )
          as _i3.FirebaseStorage);

  @override
  String get bucket =>
      (super.noSuchMethod(
            Invocation.getter(#bucket),
            returnValue: _i6.dummyValue<String>(
              this,
              Invocation.getter(#bucket),
            ),
          )
          as String);

  @override
  String get fullPath =>
      (super.noSuchMethod(
            Invocation.getter(#fullPath),
            returnValue: _i6.dummyValue<String>(
              this,
              Invocation.getter(#fullPath),
            ),
          )
          as String);

  @override
  String get name =>
      (super.noSuchMethod(
            Invocation.getter(#name),
            returnValue: _i6.dummyValue<String>(this, Invocation.getter(#name)),
          )
          as String);

  @override
  _i3.Reference get root =>
      (super.noSuchMethod(
            Invocation.getter(#root),
            returnValue: _FakeReference_2(this, Invocation.getter(#root)),
          )
          as _i3.Reference);

  @override
  _i3.Reference child(String? path) =>
      (super.noSuchMethod(
            Invocation.method(#child, [path]),
            returnValue: _FakeReference_2(
              this,
              Invocation.method(#child, [path]),
            ),
          )
          as _i3.Reference);

  @override
  _i5.Future<void> delete() =>
      (super.noSuchMethod(
            Invocation.method(#delete, []),
            returnValue: _i5.Future<void>.value(),
            returnValueForMissingStub: _i5.Future<void>.value(),
          )
          as _i5.Future<void>);

  @override
  _i5.Future<String> getDownloadURL() =>
      (super.noSuchMethod(
            Invocation.method(#getDownloadURL, []),
            returnValue: _i5.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(#getDownloadURL, []),
              ),
            ),
          )
          as _i5.Future<String>);

  @override
  _i5.Future<_i4.FullMetadata> getMetadata() =>
      (super.noSuchMethod(
            Invocation.method(#getMetadata, []),
            returnValue: _i5.Future<_i4.FullMetadata>.value(
              _FakeFullMetadata_4(this, Invocation.method(#getMetadata, [])),
            ),
          )
          as _i5.Future<_i4.FullMetadata>);

  @override
  _i5.Future<_i3.ListResult> list([_i4.ListOptions? options]) =>
      (super.noSuchMethod(
            Invocation.method(#list, [options]),
            returnValue: _i5.Future<_i3.ListResult>.value(
              _FakeListResult_5(this, Invocation.method(#list, [options])),
            ),
          )
          as _i5.Future<_i3.ListResult>);

  @override
  _i5.Future<_i3.ListResult> listAll() =>
      (super.noSuchMethod(
            Invocation.method(#listAll, []),
            returnValue: _i5.Future<_i3.ListResult>.value(
              _FakeListResult_5(this, Invocation.method(#listAll, [])),
            ),
          )
          as _i5.Future<_i3.ListResult>);

  @override
  _i5.Future<_i7.Uint8List?> getData([int? maxSize = 10485760]) =>
      (super.noSuchMethod(
            Invocation.method(#getData, [maxSize]),
            returnValue: _i5.Future<_i7.Uint8List?>.value(),
          )
          as _i5.Future<_i7.Uint8List?>);

  @override
  _i3.UploadTask putData(
    _i7.Uint8List? data, [
    _i4.SettableMetadata? metadata,
  ]) =>
      (super.noSuchMethod(
            Invocation.method(#putData, [data, metadata]),
            returnValue: _FakeUploadTask_6(
              this,
              Invocation.method(#putData, [data, metadata]),
            ),
          )
          as _i3.UploadTask);

  @override
  _i3.UploadTask putBlob(dynamic blob, [_i4.SettableMetadata? metadata]) =>
      (super.noSuchMethod(
            Invocation.method(#putBlob, [blob, metadata]),
            returnValue: _FakeUploadTask_6(
              this,
              Invocation.method(#putBlob, [blob, metadata]),
            ),
          )
          as _i3.UploadTask);

  @override
  _i3.UploadTask putFile(_i8.File? file, [_i4.SettableMetadata? metadata]) =>
      (super.noSuchMethod(
            Invocation.method(#putFile, [file, metadata]),
            returnValue: _FakeUploadTask_6(
              this,
              Invocation.method(#putFile, [file, metadata]),
            ),
          )
          as _i3.UploadTask);

  @override
  _i3.UploadTask putString(
    String? data, {
    _i4.PutStringFormat? format = _i4.PutStringFormat.raw,
    _i4.SettableMetadata? metadata,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #putString,
              [data],
              {#format: format, #metadata: metadata},
            ),
            returnValue: _FakeUploadTask_6(
              this,
              Invocation.method(
                #putString,
                [data],
                {#format: format, #metadata: metadata},
              ),
            ),
          )
          as _i3.UploadTask);

  @override
  _i5.Future<_i4.FullMetadata> updateMetadata(_i4.SettableMetadata? metadata) =>
      (super.noSuchMethod(
            Invocation.method(#updateMetadata, [metadata]),
            returnValue: _i5.Future<_i4.FullMetadata>.value(
              _FakeFullMetadata_4(
                this,
                Invocation.method(#updateMetadata, [metadata]),
              ),
            ),
          )
          as _i5.Future<_i4.FullMetadata>);

  @override
  _i3.DownloadTask writeToFile(_i8.File? file) =>
      (super.noSuchMethod(
            Invocation.method(#writeToFile, [file]),
            returnValue: _FakeDownloadTask_7(
              this,
              Invocation.method(#writeToFile, [file]),
            ),
          )
          as _i3.DownloadTask);
}

/// A class which mocks [TaskSnapshot].
///
/// See the documentation for Mockito's code generation for more information.
class MockTaskSnapshot extends _i1.Mock implements _i3.TaskSnapshot {
  MockTaskSnapshot() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.FirebaseStorage get storage =>
      (super.noSuchMethod(
            Invocation.getter(#storage),
            returnValue: _FakeFirebaseStorage_3(
              this,
              Invocation.getter(#storage),
            ),
          )
          as _i3.FirebaseStorage);

  @override
  int get bytesTransferred =>
      (super.noSuchMethod(Invocation.getter(#bytesTransferred), returnValue: 0)
          as int);

  @override
  _i3.Reference get ref =>
      (super.noSuchMethod(
            Invocation.getter(#ref),
            returnValue: _FakeReference_2(this, Invocation.getter(#ref)),
          )
          as _i3.Reference);

  @override
  _i4.TaskState get state =>
      (super.noSuchMethod(
            Invocation.getter(#state),
            returnValue: _i4.TaskState.paused,
          )
          as _i4.TaskState);

  @override
  int get totalBytes =>
      (super.noSuchMethod(Invocation.getter(#totalBytes), returnValue: 0)
          as int);
}

/// A class which mocks [UploadTask].
///
/// See the documentation for Mockito's code generation for more information.
class MockUploadTask extends _i1.Mock implements _i3.UploadTask {
  MockUploadTask() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.FirebaseStorage get storage =>
      (super.noSuchMethod(
            Invocation.getter(#storage),
            returnValue: _FakeFirebaseStorage_3(
              this,
              Invocation.getter(#storage),
            ),
          )
          as _i3.FirebaseStorage);

  @override
  _i5.Stream<_i3.TaskSnapshot> get snapshotEvents =>
      (super.noSuchMethod(
            Invocation.getter(#snapshotEvents),
            returnValue: _i5.Stream<_i3.TaskSnapshot>.empty(),
          )
          as _i5.Stream<_i3.TaskSnapshot>);

  @override
  _i3.TaskSnapshot get snapshot =>
      (super.noSuchMethod(
            Invocation.getter(#snapshot),
            returnValue: _FakeTaskSnapshot_8(
              this,
              Invocation.getter(#snapshot),
            ),
          )
          as _i3.TaskSnapshot);

  @override
  _i5.Future<bool> pause() =>
      (super.noSuchMethod(
            Invocation.method(#pause, []),
            returnValue: _i5.Future<bool>.value(false),
          )
          as _i5.Future<bool>);

  @override
  _i5.Future<bool> resume() =>
      (super.noSuchMethod(
            Invocation.method(#resume, []),
            returnValue: _i5.Future<bool>.value(false),
          )
          as _i5.Future<bool>);

  @override
  _i5.Future<bool> cancel() =>
      (super.noSuchMethod(
            Invocation.method(#cancel, []),
            returnValue: _i5.Future<bool>.value(false),
          )
          as _i5.Future<bool>);

  @override
  _i5.Stream<_i3.TaskSnapshot> asStream() =>
      (super.noSuchMethod(
            Invocation.method(#asStream, []),
            returnValue: _i5.Stream<_i3.TaskSnapshot>.empty(),
          )
          as _i5.Stream<_i3.TaskSnapshot>);

  @override
  _i5.Future<_i3.TaskSnapshot> catchError(
    Function? onError, {
    bool Function(Object)? test,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#catchError, [onError], {#test: test}),
            returnValue: _i5.Future<_i3.TaskSnapshot>.value(
              _FakeTaskSnapshot_8(
                this,
                Invocation.method(#catchError, [onError], {#test: test}),
              ),
            ),
          )
          as _i5.Future<_i3.TaskSnapshot>);

  @override
  _i5.Future<S> then<S>(
    _i5.FutureOr<S> Function(_i3.TaskSnapshot)? onValue, {
    Function? onError,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#then, [onValue], {#onError: onError}),
            returnValue:
                _i6.ifNotNull(
                  _i6.dummyValueOrNull<S>(
                    this,
                    Invocation.method(#then, [onValue], {#onError: onError}),
                  ),
                  (S v) => _i5.Future<S>.value(v),
                ) ??
                _FakeFuture_9<S>(
                  this,
                  Invocation.method(#then, [onValue], {#onError: onError}),
                ),
          )
          as _i5.Future<S>);

  @override
  _i5.Future<_i3.TaskSnapshot> whenComplete(
    _i5.FutureOr<dynamic> Function()? action,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#whenComplete, [action]),
            returnValue: _i5.Future<_i3.TaskSnapshot>.value(
              _FakeTaskSnapshot_8(
                this,
                Invocation.method(#whenComplete, [action]),
              ),
            ),
          )
          as _i5.Future<_i3.TaskSnapshot>);

  @override
  _i5.Future<_i3.TaskSnapshot> timeout(
    Duration? timeLimit, {
    _i5.FutureOr<_i3.TaskSnapshot> Function()? onTimeout,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#timeout, [timeLimit], {#onTimeout: onTimeout}),
            returnValue: _i5.Future<_i3.TaskSnapshot>.value(
              _FakeTaskSnapshot_8(
                this,
                Invocation.method(
                  #timeout,
                  [timeLimit],
                  {#onTimeout: onTimeout},
                ),
              ),
            ),
          )
          as _i5.Future<_i3.TaskSnapshot>);
}

/// Android 동기화는 순서대로 실행합니다. 대기를 끝내도 원래 호출은 취소되지
/// 않으므로, 시간 초과 후에도 다음 호출이 앞선 호출을 추월하지 않게 합니다.
class SnapshotSync<T> {
  SnapshotSync(this.action, this.timeout);
  final Future<void> Function(T) action;
  final Duration timeout;
  Future<void> _tail = Future<void>.value();
  Future<void>? _active;
  int? _revision;

  Future<void> run(int revision, T snapshot, void Function(Object?) onSettled) {
    if (_revision == revision && _active != null) {
      return _active!.timeout(timeout);
    }
    final job = _tail.then((_) => action(snapshot));
    _revision = revision;
    _active = job;
    void finish(Object? error) {
      if (identical(_active, job)) _active = null;
      onSettled(error);
    }

    _tail = job.then<void>(
      (_) => finish(null),
      onError: (Object error, StackTrace stack) => finish(error),
    );
    return job.timeout(timeout);
  }
}

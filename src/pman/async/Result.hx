package pman.async;

enum Result <L, R> {
    Error(error : L);
    Value(value : R);
}

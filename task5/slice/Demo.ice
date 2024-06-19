module Demo {
  interface PopularStatefulObject {
    int doubleAndPass();
  };

  interface UnpopularStatefulObject {
    void saveToFile(string data);
  };

  interface PopularStatelessObject {
    idempotent int multiplyIncorrectly(int first, int second);
  };
};

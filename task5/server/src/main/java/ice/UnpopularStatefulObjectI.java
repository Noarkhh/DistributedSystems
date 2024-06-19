package ice;

import com.zeroc.Ice.Current;
import com.zeroc.Ice.Util;

public class UnpopularStatefulObjectI implements Demo.UnpopularStatefulObject {
  private final int servantId;

  public UnpopularStatefulObjectI(int id) {
    servantId = id;
    System.out.println("Created new Unpopular Stateful servant with id " + id);
  }

  public void saveToFile(String data, Current current) {
    System.out.println("saveToFile called on object "
      + Util.identityToString(current.id) + ", servant id: " + servantId + ", data: " + data);
  }
}

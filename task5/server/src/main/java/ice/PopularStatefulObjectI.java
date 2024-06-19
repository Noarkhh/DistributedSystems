package ice;

import com.zeroc.Ice.Current;
import com.zeroc.Ice.Util;

public class PopularStatefulObjectI implements Demo.PopularStatefulObject {
  private final int servantId;
  private int counter = 1;

  public PopularStatefulObjectI(int id) {
    servantId = id;
    System.out.println("Created new Popular Stateful servant with id " + id);
  }

  public int doubleAndPass(Current current) {
    System.out.println("doubleAndPass called on object "
      + Util.identityToString(current.id) + ", servant id: " + servantId);
    return counter *= 2;
  }

}

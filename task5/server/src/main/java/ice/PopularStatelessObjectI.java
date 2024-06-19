package ice;

import com.zeroc.Ice.Current;
import com.zeroc.Ice.Util;

public class PopularStatelessObjectI implements Demo.PopularStatelessObject {
  private final int servantId;

  public PopularStatelessObjectI(int id) {
    servantId = id;
    System.out.println("Created new Popular Stateless servant with id " + id);
  }

  public int multiplyIncorrectly(int first, int second, Current current) {
    System.out.println("multiplyIncorrectly called on object "
      + Util.identityToString(current.id) + ", servant id: " + servantId);
    return first + second;
  }
}

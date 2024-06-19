package ice;

import com.zeroc.Ice.*;
import com.zeroc.Ice.Object;

class UnpopularStatefulServantLocator implements ServantLocator {
  private int assignedId = 1;

  public ServantLocator.LocateResult locate(Current current) {
    UnpopularStatefulObjectI unpopularStatefulObjectI = new UnpopularStatefulObjectI(assignedId++);
    return new ServantLocator.LocateResult(unpopularStatefulObjectI, null);
  }

  public void finished(Current current, Object servant, java.lang.Object cookie) {}
  public void deactivate(String category) {}
}

public class Server {
  private void serve(String[] args) {
    try(com.zeroc.Ice.Communicator communicator = Util.initialize(args  )) {
      ObjectAdapter adapter = communicator.createObjectAdapter("DemoAdapter");

      Object popularStatefulObjectI = new PopularStatefulObjectI(1);
      adapter.add(popularStatefulObjectI, Util.stringToIdentity("singleton"));

      UnpopularStatefulServantLocator sl = new UnpopularStatefulServantLocator();
      adapter.addServantLocator(sl, "unpopular_stateful");

      PopularStatelessObjectI popularStatelessObjectI = new PopularStatelessObjectI(1);
      adapter.addDefaultServant(popularStatelessObjectI, "popular_stateless");

      adapter.activate();
      System.out.println("Entering event processing loop...");
      communicator.waitForShutdown();
    }
  }

  public static void main(String[] args) {
    Server app = new Server();
    app.serve(args);
  }
}

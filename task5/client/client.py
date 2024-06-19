import sys, Ice
import Demo

def handle_exit(communicator, exit_code):
    communicator.destroy()
    exit(exit_code)

def main():
    communicator = Ice.initialize(sys.argv)
    properties = communicator.getProperties()
    endpoints = properties.getProperty("Demo.Endpoints")

    while True:
        inp = input("> ")
        if len(inp) == 0: continue
        split_inp = inp.split()
        match split_inp[0]:
            case "quit":
                handle_exit(communicator, 0)
            case "popular_stateful":
                base = communicator.stringToProxy(f"singleton:{endpoints}")
                popular_stateful_object = Demo.PopularStatefulObjectPrx.checkedCast(base)
                if not popular_stateful_object:
                    print("Invalid proxy")
                    continue
                value = popular_stateful_object.doubleAndPass()
                print(f"Value after doubling: {value}")
            case "unpopular_stateful":
                if len(split_inp) < 3:
                    print("Expected 3 arguments")
                    continue
                object_id = split_inp[1]
                base = communicator.stringToProxy(f"{object_id}:{endpoints}")
                try:
                    unpopular_stateful_object = Demo.UnpopularStatefulObjectPrx.checkedCast(base)
                    if not unpopular_stateful_object:
                        print("Invalid proxy")
                        continue
                    unpopular_stateful_object.saveToFile(split_inp[2])
                    print(f"Called `saveToFile` with {split_inp[2]}")
                except Ice.ObjectNotExistException:
                    print("This object does not exist")
                    continue
            case "popular_stateless":
                if len(split_inp) < 4:
                    print("Expected 4 arguments")
                    continue
                object_id = split_inp[1]
                base = communicator.stringToProxy(f"{object_id}:{endpoints}")
                try:
                    popular_stateless_object = Demo.PopularStatelessObjectPrx.checkedCast(base)
                    if not popular_stateless_object:
                        print("Invalid proxy")
                        continue
                    word = popular_stateless_object.multiplyIncorrectly(int(split_inp[2]), int(split_inp[3]))
                    print(f"Multiplied incorrectly: {word}")
                except Ice.ObjectNotExistException:
                    print("This object does not exist")
                    continue
            case _:
                print("Invalid command")

if __name__ == "__main__":
    main()

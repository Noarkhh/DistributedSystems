import { loadPackageDefinition, credentials } from "@grpc/grpc-js";
import { loadSync } from "@grpc/proto-loader";
import path from "path";
import { createInterface } from "readline";

const PROTO_PATH = path.join(
  new URL(import.meta.url).pathname,
  "../../protos/mpeg_standard_notifier.proto"
);

const packageDefinition = loadSync(
  PROTO_PATH,
  {
    keepCase: true,
    longs: String,
    enums: String,
    defaults: true,
    oneofs: true
  });

const mpegStandardNotifier = loadPackageDefinition(packageDefinition).mpeg_standard_notifier;

const handleCall = call => {
  call.on("data", (response) => {
    console.log("--------------------");
    console.log(`MPEG-${response.mpeg_part}`)
    console.log(`ISO/IEC ${response.iso_iec_standard_series_number}-${response.standard_part}:${response.edition}`)
    console.log(`Part ${response.standard_part}: Advanced ${response.media_type} Coding`)
    if (response.cooperators.length > 0) console.log("In cooperation with:");
    response.cooperators.forEach(cooperator => {
      console.log(`* ${cooperator}`);
    });
    console.log("--------------------");
  });
  call.on("end", () => console.log("Connection finished"));
  call.on("error", (e) => console.error(`Connection broken: ${e}`));
}

const validateArgs = (args, args_num) => {
  if (args.length < args_num) {
    console.log(`Invalid number of args, expected at least ${args_num}`);
    return true;
  }
  return false;
}

const main = () => {
  const target = "localhost:20000";
  const client = new mpegStandardNotifier.MPEGStandardNotifier(target,
    credentials.createInsecure());

  const readline = createInterface({
    input: process.stdin,
    output: process.stdout,
    terminal: false
  });

  const calls = [];

  readline.on("line", line => {
    const args = line.split(" ");
    let request = {};

    if (validateArgs(args, 1)) return;

    switch (args[0]) {
      case "mpeg_part":
        if (validateArgs(args, 3)) return;
        request = { media_types: args.slice(2), mpeg_part: parseInt(args[1]) };
        break;
      case "standard_part":
        if (validateArgs(args, 3)) return;
        request = { media_types: args.slice(2), standard_part: parseInt(args[1]) };
        break;
      case "edition":
        if (validateArgs(args, 3)) return;
        request = { media_types: args.slice(2), edition: parseInt(args[1]) };
        break;
      case "cooperator":
        if (validateArgs(args, 3)) return;
        request = { media_types: args.slice(2), cooperator: args[1] };
        break;
      case "cancel":
        if (validateArgs(args, 2)) return;
        calls.at(parseInt(args[1])).cancel();
        console.log(`Cancelled subscribtion nr ${args[1]}`);
        return;
      default:
        console.error("Invalid command!");
        return;
    }
    calls.push(client.subscribeForStandards(request));
    handleCall(calls.at(-1));
    console.log(`Subscribtion nr ${calls.length - 1}`);

  })
}

main();

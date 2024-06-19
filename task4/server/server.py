from generated import mpeg_standard_notifier_pb2, mpeg_standard_notifier_pb2_grpc 
from concurrent import futures
import random
import time
import grpc
import threading

COLLABORATORS = ["ITU-T", "The_FFMpeg_Council", "The_Church_of_Mormon", "PRC"]
MEDIA_TYPES = [
    mpeg_standard_notifier_pb2.Video,
    mpeg_standard_notifier_pb2.Audio,
    mpeg_standard_notifier_pb2.Scent,
    mpeg_standard_notifier_pb2.Flavour,
    mpeg_standard_notifier_pb2.Tactile
]

class MPEGConsortium:
    def __init__(self) -> None:
        self.mpeg_parts = [{
                "mpeg_part": 22,
                "iso_iec_standard_series_number": 34621,
                "standard_parts": [{
                        "standard_part": 0,
                        "title": "ABC",
                        "edition": 2030,
                        "media_type": mpeg_standard_notifier_pb2.Audio,
                        "cooperators": []
                    }]
            }]
        self.current_year = 2030
        
    def get_new_standard(self) -> mpeg_standard_notifier_pb2.Standard:
        self.current_year += 1
        if random.randrange(0, 10) == 0:
            self.create_new_mpeg_part()
            return self.create_standard(-1, 0)
        random_mpeg_part_index = random.randrange(0, len(self.mpeg_parts))
        self.create_new_mpeg_standard_part(self.mpeg_parts[random_mpeg_part_index])
        return self.create_standard(random_mpeg_part_index, -1)

    def create_new_mpeg_part(self) -> None:
        last_mpeg_part = self.mpeg_parts[-1]
        mpeg_part = last_mpeg_part["mpeg_part"] + random.randrange(0, 5)
        iso_iec_standard_series_number = last_mpeg_part["iso_iec_standard_series_number"] + random.randrange(0, 300)
        mpeg_part = {
            "mpeg_part": mpeg_part,
            "iso_iec_standard_series_number": iso_iec_standard_series_number,
            "standard_parts": []
        }
        self.create_new_mpeg_standard_part(mpeg_part) 
        self.mpeg_parts.append(mpeg_part)

    def create_new_mpeg_standard_part(self, mpeg_part: dict) -> None:
        standard_part = len(mpeg_part["standard_parts"])
        title = "Test"
        edition = self.current_year
        media_type = random.choice(MEDIA_TYPES)
        cooperators = []
        for cooperator in COLLABORATORS:
            if random.randrange(0, 2) == 0:
                cooperators.append(cooperator)

        mpeg_part["standard_parts"].append({
            "standard_part": standard_part,
            "title": title,
            "edition": edition,
            "media_type": media_type,
            "cooperators": cooperators
        })

    def create_standard(self, mpeg_part_index: int, standard_part_index: int) -> mpeg_standard_notifier_pb2.Standard:
        mpeg_part = self.mpeg_parts[mpeg_part_index]
        standard = mpeg_part["standard_parts"][standard_part_index]
        return mpeg_standard_notifier_pb2.Standard(
            mpeg_part=mpeg_part["mpeg_part"],
            standard_part=standard["standard_part"],
            media_type=standard["media_type"],
            iso_iec_standard_series_number=mpeg_part["iso_iec_standard_series_number"],
            edition=standard["edition"],
            title=standard["title"],
            cooperators=standard["cooperators"]
        )


class MPEGNotifier:
    def __init__(self) -> None:
        self.mpeg_consortium = MPEGConsortium()
        self.new_standards = []
        self.queues: dict[str, list] = {}
        self.queues_lock = threading.Lock()

    def loop(self) -> None:
        while True:
            time.sleep(1)
            new_standard = self.mpeg_consortium.get_new_standard()
            self.queues_lock.acquire()
            for q in self.queues.values():
                q.append(new_standard)
            self.queues_lock.release()

    def handle_connection_closed(self, context) -> None:
        print(f"Connection was cancelled, peer: {context.peer()}")
        self.queues_lock.acquire()
        self.queues.pop(str(context.peer()))
        self.queues_lock.release()

    def SubscribeForStandards(self, request, context):
        print(f"Received subscription from {context.peer()}")
        self.queues_lock.acquire()
        self.queues[str(context.peer())] = []
        self.queues_lock.release()
        context.add_callback(lambda: self.handle_connection_closed(context))

        while True:
            time.sleep(0.5)
            self.queues_lock.acquire()
            if len(self.queues[str(context.peer())]) > 0:
                new_standard = self.queues[str(context.peer())].pop(0)
            else:
                new_standard = None
            self.queues_lock.release()
            if new_standard is None or new_standard.media_type not in request.media_types:
                continue
            if request.HasField("mpeg_part") and new_standard.mpeg_part == request.mpeg_part:
                print(f"Sent standard to {context.peer()}")
                yield new_standard
                continue
            if request.HasField("standard_part") and new_standard.standard_part >= request.standard_part:
                print(f"Sent standard to {context.peer()}")
                yield new_standard
                continue
            if request.HasField("edition") and new_standard.edition >= request.edition:
                print(f"Sent standard to {context.peer()}")
                yield new_standard
                continue
            if request.HasField("cooperator") and request.cooperator in new_standard.cooperators:
                print(f"Sent standard to {context.peer()}")
                yield new_standard
                continue

def serve():
    server = grpc.server(futures.ThreadPoolExecutor(max_workers=10))
    mpeg_notifier = MPEGNotifier()
    mpeg_standard_notifier_pb2_grpc.add_MPEGStandardNotifierServicer_to_server(mpeg_notifier, server)
    server.add_insecure_port('[::]:20000')
    server.start()
    print("Server started")
    mpeg_notifier.loop()
    server.wait_for_termination()


if __name__ == '__main__':
    serve()


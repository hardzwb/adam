#!/usr/bin/env python3
"""Cycle-level functional model for sio_clink_pack -> sio_clink_unpack.

This is not an HDL simulator. It mirrors the RTL-visible frame mapping and
dat segment stream rules so the loopback behavior can be checked in an
environment where no Verilog simulator is installed.
"""

SEG_W = 52
SEG_MASK = (1 << SEG_W) - 1
DAT_SEG_604 = 12
DAT_SEG_668 = 13


def dat_seg_count(dat):
    return DAT_SEG_604 if (dat >> 604) == 0 else DAT_SEG_668


def dat_segments(dat):
    return [(dat >> (idx * SEG_W)) & SEG_MASK for idx in range(dat_seg_count(dat))]


def make_dat(seed, size604=False):
    width = 604 if size604 else 668
    value = 0
    for bit in range(0, width, 17):
        value ^= ((seed + bit * 13) & ((1 << 17) - 1)) << bit
    value &= (1 << width) - 1
    if not size604:
        value |= 1 << 660
    return value


class PackerModel:
    def __init__(self):
        self.dat_queue = []

    @staticmethod
    def dat_cap(req_vld, rsp_vld):
        if req_vld and rsp_vld:
            return 10
        if req_vld:
            return 11
        if rsp_vld:
            return 13
        return 14

    def step(self, req=None, rsp=None, dat=None):
        if dat is not None:
            size604 = dat_seg_count(dat) == DAT_SEG_604
            for idx, seg in enumerate(dat_segments(dat)):
                self.dat_queue.append({
                    "seg": seg,
                    "new": idx == 0,
                    "size604": size604,
                })

        req_vld = req is not None
        rsp_vld = rsp is not None
        cap = self.dat_cap(req_vld, rsp_vld)
        dat_window = self.dat_queue[:cap]
        dat_vld = len(dat_window) != 0
        dat_new = any(item["new"] for item in dat_window)
        dat_size604 = next((item["size604"] for item in dat_window if item["new"]), False)
        frame_type = (
            (req_vld << 4) |
            (rsp_vld << 3) |
            (dat_vld << 2) |
            (dat_new << 1) |
            dat_size604
        )

        frame = {
            "frame_type": frame_type,
            "req": req,
            "rsp": rsp,
            "dat_window": [item["seg"] for item in dat_window],
        }
        self.dat_queue = self.dat_queue[cap:]
        return frame


class UnpackerModel:
    def __init__(self):
        self.active = False
        self.size604 = False
        self.asm = []

    @staticmethod
    def dat_cap(frame_type):
        req = (frame_type >> 4) & 1
        rsp = (frame_type >> 3) & 1
        if req and rsp:
            return 10
        if req:
            return 11
        if rsp:
            return 13
        return 14

    def step(self, frame):
        frame_type = frame["frame_type"]
        outputs = {
            "req": frame["req"] if ((frame_type >> 4) & 1) else None,
            "rsp": frame["rsp"] if ((frame_type >> 3) & 1) else None,
            "dat": None,
            "dat_size604": None,
            "frame_type": frame_type,
        }

        if ((frame_type >> 2) & 1) == 0:
            return outputs

        cap = self.dat_cap(frame_type)
        window = frame["dat_window"][:cap]
        new = (frame_type >> 1) & 1
        new_size604 = bool(frame_type & 1)

        if self.active:
            total = DAT_SEG_604 if self.size604 else DAT_SEG_668
            remaining = total - len(self.asm)
            take = min(cap, remaining)
            self.asm.extend(window[:take])
            if take == remaining:
                outputs["dat"] = self.pack_dat(self.asm)
                outputs["dat_size604"] = self.size604
                self.asm = []
                self.active = False

                leftover = cap - remaining
                if leftover and new:
                    self.asm = window[remaining:remaining + leftover]
                    self.active = True
                    self.size604 = new_size604
        else:
            self.size604 = new_size604
            total = DAT_SEG_604 if self.size604 else DAT_SEG_668
            take = min(cap, total)
            self.asm = window[:take]
            self.active = True
            if take == total:
                outputs["dat"] = self.pack_dat(self.asm)
                outputs["dat_size604"] = self.size604
                self.asm = []
                self.active = False

        return outputs

    @staticmethod
    def pack_dat(segments):
        value = 0
        for idx, seg in enumerate(segments):
            value |= (seg & SEG_MASK) << (idx * SEG_W)
        return value & ((1 << 668) - 1)


def run_sequence(name, cycles, expected_reqs, expected_rsps, expected_dats):
    packer = PackerModel()
    unpacker = UnpackerModel()
    got_reqs = []
    got_rsps = []
    got_dats = []
    frame_types = []

    for cycle in cycles:
        frame = packer.step(**cycle)
        out = unpacker.step(frame)
        frame_types.append(frame["frame_type"])
        if out["req"] is not None:
            got_reqs.append(out["req"])
        if out["rsp"] is not None:
            got_rsps.append(out["rsp"])
        if out["dat"] is not None:
            got_dats.append((out["dat"], out["dat_size604"]))

    assert got_reqs == expected_reqs, (name, "req", got_reqs, expected_reqs)
    assert got_rsps == expected_rsps, (name, "rsp", got_rsps, expected_rsps)
    assert got_dats == expected_dats, (name, "dat", got_dats, expected_dats)
    print(f"PASS {name}: frames={[format(ft, '05b') for ft in frame_types]}")


def main():
    req_a = (1 << 157) | 0x123456789abcdef
    rsp_a = (1 << 69) | 0x23456789a
    dat668_a = make_dat(0x1234, size604=False)
    dat668_b = make_dat(0x5678, size604=False)
    dat604_a = make_dat(0x2468, size604=True)

    run_sequence(
        "req_rsp_only",
        [{"req": req_a, "rsp": rsp_a, "dat": None}],
        [req_a],
        [rsp_a],
        [],
    )

    run_sequence(
        "dat668_only",
        [{"req": None, "rsp": None, "dat": dat668_a}],
        [],
        [],
        [(dat668_a, False)],
    )

    run_sequence(
        "dat604_only",
        [{"req": None, "rsp": None, "dat": dat604_a}],
        [],
        [],
        [(dat604_a, True)],
    )

    run_sequence(
        "req_rsp_dat668_split",
        [
            {"req": req_a, "rsp": rsp_a, "dat": dat668_a},
            {"req": None, "rsp": None, "dat": None},
        ],
        [req_a],
        [rsp_a],
        [(dat668_a, False)],
    )

    run_sequence(
        "dat_tail_plus_next_head",
        [
            {"req": req_a, "rsp": rsp_a, "dat": dat668_a},
            {"req": None, "rsp": None, "dat": dat668_b},
            {"req": None, "rsp": None, "dat": None},
        ],
        [req_a],
        [rsp_a],
        [(dat668_a, False), (dat668_b, False)],
    )


if __name__ == "__main__":
    main()

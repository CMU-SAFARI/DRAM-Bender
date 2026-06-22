def map_row(physical_id: int) -> int:
    parity = (physical_id & 0x5408).bit_count() & 1
    return physical_id ^ (parity * 0x6)

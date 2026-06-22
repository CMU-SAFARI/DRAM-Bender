def map_row(physical_id: int) -> int:
    return physical_id ^ (((physical_id >> 3) & 1) * 0x6)

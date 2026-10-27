"""Pemeriksa robots.txt. Pemantau hanya mengambil laman yang diizinkan (NFR-SM-02)."""

from urllib.robotparser import RobotFileParser

USER_AGENT = "SMART-Pemantau/0.1"


def boleh_diambil(isi_robots: str, url: str, user_agent: str = USER_AGENT) -> bool:
    parser = RobotFileParser()
    parser.parse(isi_robots.splitlines())
    return parser.can_fetch(user_agent, url)

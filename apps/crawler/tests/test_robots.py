from smart_crawler.robots import boleh_diambil

ROBOTS = "User-agent: *\nDisallow: /privat/\n"


def test_laman_diizinkan():
    assert boleh_diambil(ROBOTS, "https://contoh.example/beasiswa")


def test_laman_dilarang():
    assert not boleh_diambil(ROBOTS, "https://contoh.example/privat/data")

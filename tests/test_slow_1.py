import time

def test_slow_suite_1():
    # Stands in for a long integration suite. Sleeps 27 s to give split_tests timing data.
    time.sleep(27)
    assert True

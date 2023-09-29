import unittest
from mymodule import add

class TestAddFunction(unittest.TestCase):

    def test_add_positive_numbers(self):
        result = add(2, 2)
        self.assertEqual(result, 4)

    def test_add_negative_numbers(self):
        result = add(-2, -2)
        self.assertEqual(result, -4)

    def test_add_mixed_numbers(self):
        result = add(1, -3)
        self.assertEqual(result, -2)

if __name__ == '__main__':
    unittest.main()

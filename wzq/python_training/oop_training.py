#!/usr/bin/python
# encoding: utf-8
'''
@Author: EganWeng
@Contact: eganweng@163.com
@File: oop_training.py
@Time: 4/11/2021 8:36 PM
'''


class Dot(object):
    name1 = 'Dot'

    def print_a(self):
        print("I am a Dot.")


class Line(Dot):

    def print_a(self):
        print("I am a Line.")

    def __init__(self, name = ''):
        self.name = name


class Plane(Line):

    def print_a(self):
        print("I am a Plane.")


class Stereo(Plane):

    def print_a(self):
        print("I am a Stereo.")


if __name__ == '__main__':
    print(__name__)
    dot = Dot()
    plane = Plane()
    print(type(dot))
    print(type(plane))
    plane = dot
    plane.print_a()




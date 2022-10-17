import docker
import logging
import os
from unittest import TestCase
from cli.configuration import ImageManager

logging.basicConfig(level=logging.INFO)


class TestImageManager(TestCase):

    def setUp(self):
        self.docker_client = docker.from_env(timeout=3000)

    def test_get_export_file_path(self):
        script_folder = os.path.dirname(os.path.realpath('__file__'))
        target_folder = 'test'
        expected_file_path = f'{script_folder}/{target_folder}/mm-patient-count.tar'
        file_path = ImageManager.get_export_file_path('harbor-uat.athenafederation.org/script/mm-patient-count:1.0.0',
                                                      target_folder=target_folder)
        print(file_path)
        self.assertEqual(expected_file_path, file_path)

    def test_export_load(self):
        export_file_path = ImageManager.export_image(self.docker_client,
                                                     image_name_tag='harbor-uat.athenafederation.org/script/mm-patient-count:1.0.0',
                                                     target_folder='test')
        ImageManager.load_image(self.docker_client, export_file_path)

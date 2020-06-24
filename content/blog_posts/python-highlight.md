---
title: Hugo Syntax Highlighting
date: 2020-06-15
categories:
  - "Development"
---

{{< highlight python >}}
from PIL import Image
from io import BytesIO
import urllib
import requests
import numpy as np
import matplotlib
import json
from .utils.conversions import convert_uint_to_float, convert_float_to_uint, round_to_uint, get_rgb_float_if_hex, get_array_from_hex
from .utils.layers import mix
from .utils.channels import split_image_into_channels, merge_channels, channel_adjust


class LayerImage():
    @staticmethod
    def from_url(url):
        response = requests.get(url)
        image = Image.open(BytesIO(response.content))
        image_data = convert_uint_to_float(np.asarray(image))

        return LayerImage(image_data)

    @staticmethod
    def from_file(file_path):
        image = Image.open(file_path)
        image_data = convert_uint_to_float(np.asarray(image))

        return LayerImage(image_data)

    @staticmethod
    def from_array(image_data):
        return LayerImage(image_data)

    def __init__(self, image_data):
        self.image_data = image_data

    def grayscale(self):
        self.image_data = np.dot(self.image_data[..., :3], [
                                 0.2989, 0.5870, 0.1140])

        self.image_data = np.stack(
            (self.image_data,) * 3, axis=-1)

        return self
{{< /highlight >}}
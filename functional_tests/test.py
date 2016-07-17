from django.contrib.staticfiles.testing import StaticLiveServerTestCase
from selenium import webdriver
from sys import argv

class FunctionalTest (StaticLiveServerTestCase):

    @classmethod
    def setUpClass (cls):
        for arg in argv:
            if arg.startswith("--liveserver="):
                # If there's a `--liveserver` argument anywhere, then we
                # set the server URL to whatever's after the equal sign.
                cls.server_url = "https://" + arg.split("=")[1]

        if getattr(cls, "server_url", None) is None:
            # If we didn't set a server URL, then we'll be using
            # Django's test server, which means we need to run its class
            # setup method.
            super().setUpClass()

            # Django puts its server URL in live_server_url.
            cls.server_url = cls.live_server_url

    @classmethod
    def tearDownClass (cls):
        if cls.server_url == getattr(cls, "live_server_url", None):
            # If our server URL is the same as Django's test server,
            # then we were using Django's test server, and we should
            # tear it down accordingly.
            super().tearDownClass()

    def setUp (self):
        self.browser = webdriver.Firefox(log_file = "/ram/ff.log")
        self.browser.implicitly_wait(3)
        self.browser.get("http://google.com")

    def tearDown (self):
        self.browser.quit()

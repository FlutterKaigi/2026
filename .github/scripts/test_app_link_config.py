"""Ensure deploy/native settings agree with the shared public host manifest."""

import json
from pathlib import Path
import plistlib
import tomllib
import unittest
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[2]
HOSTS = json.loads((ROOT / "tool/app_link_hosts.json").read_text())


def read(path):
    return (ROOT / path).read_text()


def env(flavor):
    return dict(
        line.split("=", 1)
        for line in read(f"apps/app/environments/.env.{flavor}").splitlines()
        if line and not line.startswith("#")
    )


class AppLinkConfigTest(unittest.TestCase):
    def test_native_environment_hosts(self):
        for flavor, primary in [
            ("prod", HOSTS["productionAppHost"]),
            ("stg", HOSTS["stagingAppHost"]),
            ("dev", "localhost"),
        ]:
            with self.subTest(flavor=flavor):
                self.assertEqual(env(flavor)["APP_LINK_HOST"], primary)

    def test_app_host_serves_spa_and_association_files(self):
        config = tomllib.loads(read("apps/app/wrangler.toml"))
        self.assertEqual(config["route"]["pattern"], HOSTS["productionAppHost"])
        self.assertTrue(config["route"]["custom_domain"])
        self.assertEqual(config["assets"]["not_found_handling"], "single-page-application")

    def test_website_remains_on_its_own_host(self):
        config = tomllib.loads(read("apps/website/wrangler.toml"))
        self.assertEqual(config["route"]["pattern"], HOSTS["officialWebsiteHost"])
        self.assertIn("defaultValue: officialWebsiteOrigin", read("apps/website/lib/constants/site.dart"))
        self.assertIn("'$officialWebsiteOrigin/'", read("apps/app/lib/core/constants/app_links.dart"))

    def test_workflows_verify_canonical_app_host(self):
        web = read(".github/workflows/deploy_app_web.yaml")
        self.assertIn(f"url: https://{HOSTS['productionAppHost']}", web)
        self.assertIn("s/^APP_LINK_HOST=//p", web)
        self.assertIn('--base-url "$verification_url"', web)
        website = read(".github/workflows/deploy_website.yaml")
        self.assertIn(f'--base-url https://{HOSTS["productionAppHost"]}', website)

    def test_android_filters_preserve_app_host_and_website_x_only(self):
        manifest = ET.fromstring(read("apps/app/android/app/src/main/AndroidManifest.xml"))
        ns = "{http://schemas.android.com/apk/res/android}"
        filters = manifest.findall(".//intent-filter")
        matching = [element for element in filters if any(
            data.get(ns + "host") == "${appLinkHost}" for data in element.findall("data")
        )]
        self.assertEqual(len(matching), 1)
        self.assertEqual(matching[0].get(ns + "autoVerify"), "true")
        legacy = [data for data in manifest.findall(".//data") if data.get(ns + "host") == "${legacyShareLinkHost}"]
        self.assertEqual(len(legacy), 1)
        self.assertEqual(legacy[0].get(ns + "pathPrefix"), "/x/")
        gradle = read("apps/app/android/app/build.gradle.kts")
        self.assertIn(f'"{HOSTS["officialWebsiteHost"]}" else appLinkHost', gradle)
        self.assertRegex(gradle, r'if \(dartDefines\["FLAVOR"\] == "prod"\)')

    def test_ios_reads_environment_hosts_and_keeps_website_compatibility(self):
        entitlements = plistlib.loads(read("apps/app/ios/Runner/Runner.entitlements").encode())
        self.assertEqual(entitlements["com.apple.developer.associated-domains"], [
            "applinks:$(APP_LINK_HOST)",
            f"applinks:{HOSTS['officialWebsiteHost']}",
        ])
        for build in ["Debug", "Release"]:
            config = read(f"apps/app/ios/Flutter/{build}.xcconfig")
            self.assertRegex(config, r"(?m)^APP_LINK_HOST\s*=\s*localhost$")


if __name__ == "__main__":
    unittest.main()

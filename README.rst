.. SPDX-License-Identifier: AGPL-3.0-or-later

.. _metasearch engine: https://en.wikipedia.org/wiki/Metasearch_engine
.. _Installation guide: https://docs.searxng.org/admin/installation.html
.. _Configuration guide: https://docs.searxng.org/admin/settings/index.html
.. _CONTRIBUTING: https://github.com/cognitolabs-ai/xsearch/blob/master/CONTRIBUTING.rst
.. _LICENSE: https://github.com/cognitolabs-ai/xsearch/blob/master/LICENSE

.. figure:: https://raw.githubusercontent.com/cognitolabs-ai/xsearch/master/client/simple/src/brand/searxng.svg
   :target: https://cognitolabs.eu
   :alt: XSearch by Cognitolabs AI
   :width: 512px


XSearch by Cognitolabs AI is a `metasearch engine`_. Users are neither tracked nor profiled.

.. image:: https://img.shields.io/badge/organization-3050ff?style=flat-square&logo=cognitolabs-ai&logoColor=fff&cacheSeconds=86400
   :target: https://github.com/cognitolabs-ai
   :alt: Organization

.. image:: https://img.shields.io/badge/documentation-3050ff?style=flat-square&logo=readthedocs&logoColor=fff&cacheSeconds=86400
   :target: https://docs.searxng.org
   :alt: Documentation

.. image:: https://img.shields.io/github/license/cognitolabs-ai/xsearch?style=flat-square&label=license&color=3050ff&cacheSeconds=86400
   :target: https://github.com/cognitolabs-ai/xsearch/blob/master/LICENSE
   :alt: License

.. image:: https://img.shields.io/github/commit-activity/y/cognitolabs-ai/xsearch/master?style=flat-square&label=commits&color=3050ff&cacheSeconds=3600
   :target: https://github.com/cognitolabs-ai/xsearch/commits/master/
   :alt: Commits

.. image:: https://img.shields.io/weblate/progress/searxng?server=https%3A%2F%2Ftranslate.codeberg.org&style=flat-square&label=translated&color=3050ff&cacheSeconds=86400
   :target: https://translate.codeberg.org/projects/searxng/
   :alt: Translated

Quick Start
===========

Deploy XSearch with Docker Compose:

.. code:: bash

   ./deploy.sh

Or manually:

.. code:: bash

   cp .env.example .env
   # Edit .env and set XSEARCH_BASE_URL and XSEARCH_SECRET
   docker compose up -d

Access XSearch at http://localhost:8080

For detailed deployment instructions, see `DEPLOYMENT.md <DEPLOYMENT.md>`_.

Setup
=====

To install XSearch, see `Installation guide`_.

To fine-tune XSearch, see `Configuration guide`_.

Further information on *how-to* can be found `here <https://docs.searxng.org/admin/index.html>`_.

Connect
=======

If you have questions or want to connect with others in the community:

- `#searxng:matrix.org <https://matrix.to/#/#searxng:matrix.org>`_

Contributing
============

See CONTRIBUTING_ for more details.

License
=======

This project is licensed under the GNU Affero General Public License (AGPL-3.0).
See LICENSE_ for more details.

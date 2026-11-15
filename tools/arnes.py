#!/usr/bin/env python3
"""Utilidades compartidas por las herramientas del proyecto (arnes local).

Resuelve dos limitaciones del entorno de este equipo sin cambiar el uso normal:

* MARS (Java) no puede escribir en directorios creados con ``tempfile.mkdtemp``
  (quedan con una ACL que deniega el acceso a otros procesos), asi que el arnes
  puede usar un subdirectorio dentro del repositorio mediante ``SMIPS_WORK``.
* Logisim escribe sus preferencias en el registro de Windows. Si el registro no
  esta disponible hay que cargar ``MemPrefsFactory`` en el classpath; eso se
  configura con ``SMIPS_JVM_OPTS`` y ``SMIPS_CP_EXTRA``.

Sin variables de entorno todo funciona como antes, con ``tempfile``.
"""
from contextlib import contextmanager
from pathlib import Path
import itertools
import os
import shutil
import tempfile

CONTADOR = itertools.count(1)


@contextmanager
def directorio_trabajo(prefijo):
    """Directorio de trabajo de una ejecucion (volcados de MARS e imagenes)."""
    base = os.environ.get('SMIPS_WORK')
    if not base:
        with tempfile.TemporaryDirectory(prefix=prefijo) as directorio:
            yield Path(directorio)
        return
    destino = Path(base)/(f'{prefijo}{next(CONTADOR)}')
    shutil.rmtree(destino, ignore_errors=True)
    destino.mkdir(parents=True, exist_ok=True)
    yield destino


def opciones_java():
    """Opciones -D para las JVM que cargan Logisim en este equipo."""
    return os.environ.get('SMIPS_JVM_OPTS', '').split()


def classpath(jar):
    """Classpath del jar de Logisim mas las clases locales si estan definidas."""
    extra = os.environ.get('SMIPS_CP_EXTRA')
    return jar if not extra else jar + os.pathsep + extra

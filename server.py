import requests
import subprocess
import os

from flask import Flask, request, jsonify

app = Flask(__name__)

DB = {}
in_bucket = "./in_bucket"

env = {**os.environ, "PATH": f"{os.getcwd()}/bin:{os.environ['PATH']}"}


def next_id():
    i = 0
    while f"G0{i}" in DB:
        i += 1
    return f"G0{i}"


@app.post("/upload")
def upload():
    if request.is_json:
        data = request.get_json()
        for guid in data["guids"]:
            DB[guid] = {"status": "uploaded"}
            open(f"{in_bucket}/{guid}_R1.fastq.gz", "w").close()
            open(f"{in_bucket}/{guid}_R2.fastq.gz", "w").close()

        p = subprocess.Popen(["nextflow", "run", "main.nf", "--push", "true"], env=env)
        return jsonify({"status": "Success"}), 201

    return {"error": "bad request"}, 415


@app.post("/report")
def report():
    if request.is_json:
        data = request.get_json()

        DB[guid] = {}
        return jsonify({"guid": guid}), 201

    return {"error": "bad request"}, 415


@app.post("/register")
def register():
    if request.is_json:
        data = request.get_json()
        guid = next_id()
        DB[guid] = data
        return jsonify({"guid": guid}), 201

    return {"error": "bad request"}, 415

def extract_prefix(inputString) {
  def matcher = (inputString =~ /^(.*?)\.fastq\.gz$/)
  if (matcher.matches()) {
    return matcher[0][1]
  } else {
    return null
  }
}

def get_clean_file_name(sample_name, version) {
  if (sample_name == null) {
    error('sample name is empty')
  }

  if (version != 1 && version != 2) {
    error('Version should only be 1 or 2')
  }

  prefix = extract_prefix(sample_name)
  def clean_name = "${prefix}.clean_${version}.fastq.gz"
  println("File name: ${clean_name}")
  return clean_name
}

def get_new_clean_file_name(prefix, version) {
  if (version != 1 && version != 2) {
    error('Version should only be 1 or 2')
  }

  def new_name = "${prefix}.clean_${version}.fastq.gz"
  return new_name
}

def get_report_file_name() {
  return "decontamination-log.json"
}

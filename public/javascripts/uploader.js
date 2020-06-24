// Some options to pass to the uploader are discussed on the next page
const uploader = new qq.azure.FineUploader({
  element: document.getElementById("uploader"),
  template: "qq-template-manual-trigger",
  //blobProperties: {
  //    name: 'filename'
  //},
  request: {
    endpoint: "https://<% service %>.blob.core.windows.net/<% container %>",
  },
  signature: {
    endpoint: "/signature",
  },
  uploadSuccess: {
    endpoint: "/success",
  },
  retry: {
    enableAuto: true,
  },
  deleteFile: {
    enabled: false,
  },
  autoUpload: false,
  multiple: false,
})

const uploadForm = document.querySelector("#uploader-metadata-form")

function upload() {
  const fileVersion = uploadForm.elements["file-version"].value
  const username = uploadForm.elements["username"].value
  console.log({ fileVersion, username })

  const fileId = uploader.getUploads()[0].id

  uploader.setCustomHeaders({
    "x-ms-file-version": fileVersion,
    "x-ms-username": username,
  })

  uploader.uploadStoredFiles()
}

// Also upload on form submit
uploadForm.addEventListener("submit", (e) => {
  e.preventDefault()
  upload()
})

package com.myverbatm.verbatm.backend.handlers;

import com.google.appengine.api.blobstore.BlobKey;
import com.google.appengine.api.blobstore.BlobstoreService;
import com.google.appengine.api.blobstore.BlobstoreServiceFactory;

import java.io.IOException;
import java.util.List;
import java.util.Map;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Class that handles request to upload video to the blobstore
 * (from "/uploadVideo" success uri passed when requesting an upload uri from the blobstore)
 */
public class UploadVideo extends HttpServlet {

    private BlobstoreService blobstoreService = BlobstoreServiceFactory.getBlobstoreService();

    @Override
    public void doPost(HttpServletRequest req, HttpServletResponse res)
        throws ServletException, IOException {

        try {
            Map<String, List<BlobKey>> blobs = blobstoreService.getUploads(req);
            BlobKey blobKey = blobs.get("defaultVideo").get(0);
            //Blob key can be converted back by passing string to its constructor
            res.getWriter().write(blobKey.getKeyString());
            System.out.println("Video successfully uploaded");
        }
        catch (Exception e) {
            System.out.println("Video failed to upload");
        }
    }
}

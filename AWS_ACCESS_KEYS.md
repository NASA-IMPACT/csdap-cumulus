# AWS Access Keys

In order to run AWS CLI or Terraform commands, you must obtain an AWS access
key, and set appropriate environment variables, as explained here.

Ideally, you'll want to obtain a long-term access key, but in case you are not
permitted to, you'll have to obtain a short-term access key.  Follow the
instructions for generating a long-term access key, but if you reach a step
where you cannot proceed, follow the instructions for generating a short-term
access key.

In either case, you must first create a `.env` file, if you haven't already done
so, by copying the `.env.example` file to a `.env` file at the root of this
repository.  In your `.env` file, you will set some variables as described in
the following instructions.

## Generating a Long-term Access Key

To generate a **long-term access key**, do the following:

1. If not on the NASA network, connect to the NASA VPN (if not already connected).
1. Login to the [NGAP cloudtamer.io portal](https://cloud.earthdata.nasa.gov).
1. If the appropriate project is not visible, click **Projects** in the left
   navigation bar to see a list of all of your projects.
1. Locate the desired project and click the project name to see the details.
1. Along the top row of headers, click **CLOUD MANAGEMENT**.
1. Along the second row of headers, click **AWS Long-Term Access Keys**.
1. At the right of the (possibly empty) list of AWS Long-Term Access Keys, look
   for a small icon consisting of **3 vertically arranged dots**, within the
   AWS Long-Term Access Keys pane.  If you do not see such an icon, you do not
   have permission to create long-term access keys, and you must skip the
   remainder of these steps, and instead follow the instructions for generating
   a short-term access key (see the next section).
1. Click the icon to reveal a context menu.
1. Click **Create AWS long-term access keys**.
1. In the **Generate API Key** dialog box, select the appropriate account and
   role, then click the **Generate API Key** button.
1. You should see a **Success!** dialog box with a visible **API Key ID** and a
   hidden **Secret Access Key**.
1. Copy the value of **API Key ID** to your clipboard, and
   **leave this dialog box open** for the moment.
1. Open your `.env` file in a text editor.
1. Locate the variable `AWS_ACCESS_KEY_ID` and paste the **API Key ID** (that
   you copied to your clipboard above) as the value of that variable.
1. Go back to the open dialog box in the portal and click the **Show** link at
   the right end of the string of asterisks, to show your **Secret Access Key**.
1. Copy the visible secret access key to your clipboard.
1. Go back to your `.env` file and paste the **Secret Access Key** as the value
   of the variable `AWS_SECRET_ACCESS_KEY`.
1. Save your `.env` file.

You may now close the dialog box in the portal and logout of the portal.

## Generating a Short-Term Access Key

If you are (sadly) unable to generate a long-term access key as described above,
you must generate a **short-term access key** as follows:

1. If not on the NASA network, connect to the NASA VPN (if not already connected).
1. Login to the [NGAP cloudtamer.io portal](https://cloud.earthdata.nasa.gov).
1. If the appropriate project is not visible, click **Projects** in the left
   navigation menu to see a list of all of your projects.
1. Locate the desired project and click the project name to see the details.
1. Within the **Project Details** pane, under the **Parent OU** value, click the
   **Cloud access** button to reveal a context menu.
1. Select the appropriate **account** (there may be only one account listed).
1. Select the appropriate **cloud access role**.
1. Select **Short-term Access Keys**.
1. Under **Option 1: Set AWS environment variables**, click the box containing
   the environment variables to copy them to your clipboard.  The contents of
   the box under this option should look similar to the following:

   ```plain
   export AWS_ACCESS_KEY_ID=ASIA****************
   export AWS_SECRET_ACCESS_KEY=****************************************
   export AWS_SESSION_TOKEN=************************************
   export AWS_DEFAULT_REGION=us-west-2
   ```

1. Open your `.env` file in a text editor.
1. Paste the contents of your clipboard into your `.env` file.
1. If your `.env` file contains expired values for these same environment
   variables, remove the lines with the expired values.
1. Save your `.env` file.

You may now close the dialog box in the portal and logout of the portal.

| NOTE |
| :--- |
| Unfortunately, if you are unable to create long-term access keys, you must **periodically repeat the steps above**, whenever you attempt to run an AWS CLI or Terraform command and you encounter an "expired token" error message.

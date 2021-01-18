---
title: Add a multiline environment variable to Vercel (or Heroku)
date: 2021-01-18
categories:
  - Vercel
---

One of the common issues when deploying a React project with `firebase-admin` is that a secret environment variable with a newline (`\n`) character will cause a build error.

Assume that the text below is a simplified version of your `firebase-admin` private key.

```
-----BEGIN PRIVATE KEY-----
abcde
fghij
klmno
pqrs=
-----END PRIVATE KEY-----
```

In a `.env` file, this would be represented as:

```
MY_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\nabcde\nfghij\nklmno\npqrs=\n-----END PRIVATE KEY-----\n"
```

What happens when you add a secret environment variable containing your private key value - `"-----BEGIN PRIVATE KEY-----\nabcde\nfghij\nklmno\npqrs=\n-----END PRIVATE KEY-----\n"` and redeploy?

![image](https://user-images.githubusercontent.com/1064036/104897705-4ecf8780-593e-11eb-86a9-a039b2ae1d3e.png)

Unfortunately, setting an environment variable containing newline characters (`\n`) in Vercel will throw an error while building.

```
FirebaseAppError: Failed to parse private key: Error: Invalid PEM formatted message.
```

![build-error](https://user-images.githubusercontent.com/1064036/104896463-c3092b80-593c-11eb-9078-f4a43222c5bf.png)

## Easy fix

Replace the newline characters with line breaks. Although you can do this manually, using find &amp; replace in a code editor will be much easier.

- Paste your private key value to a new tab in VS Code.
- Then, run a find &amp; replace.
- Enable regular expressions.
- Replace `\\n` with `\n`.

Before replace:
![image](https://user-images.githubusercontent.com/1064036/104901543-24cc9400-5943-11eb-91bb-750b31f135cc.png)

After replace:
![image](https://user-images.githubusercontent.com/1064036/104901842-84c33a80-5943-11eb-97c8-286bea17cd0f.png)

Copy &amp; paste the replaced version to Vercel.

![image](https://user-images.githubusercontent.com/1064036/104902268-264a8c00-5944-11eb-97b4-ff30ba42c15e.png)

Vercel will now successfully build your project (unless there are other errors).

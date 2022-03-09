import fs from "node:fs/promises";
import readlineModule from "node:readline/promises";
import path from "node:path";

(async () => {
    const readline = readlineModule.createInterface({
        input: process.stdin,
        output: process.stdout,
    });

    const args = process.argv.slice(2);

    const targetFilePath =
        args[0] ?? (await readline.question("Target file path: "));

    const outputDirPath =
        args[1] ?? (await readline.question("Output directory path: "));

    let chatNames = args?.slice(2);
    if (!args[2]) {
        const chatNamesStr = await readline.question(
            "Chat names (enclose with double quote, separate with [,]): "
        );

        chatNames = [...chatNamesStr.matchAll(/(?<=^"|,").*?(?=",|"$)/g)]
            .map((match) => match[0])
            .filter((str) => str);
    }

    readline.close();

    try {
        if (!(await fs.stat(targetFilePath)).isFile()) {
            throw "Target is not a file.";
        }

        try {
            if (!(await fs.stat(outputDirPath)).isDirectory()) {
                throw "Output path is not a directory.";
            }
        } catch (ex) {
            // Create directory if not exists
            if (ex.errno && ex.errno === -4058) {
                fs.mkdir(outputDirPath);
            } else {
                throw ex;
            }
        }

        console.log(`Target path: ${targetFilePath}`);
        console.log(`Output path: ${outputDirPath}`);
        console.log("Chats: ", chatNames.length > 0 ? chatNames : "All");

        // Get conversations node only
        let { conversations } = JSON.parse(
            await fs.readFile(targetFilePath, "utf8")
        );

        if (chatNames.length > 0) {
            conversations = conversations.filter(
                (conv) =>
                    conv.displayName && chatNames.includes(conv.displayName)
            );
        }

        const convUrls = Object.fromEntries(
            conversations.map((conv) => [conv.displayName, extractUrls(conv)])
        );

        await fs.writeFile(
            path.join(outputDirPath, "urls-result.json"),
            JSON.stringify(convUrls),
            "utf8"
        );

        console.log("-".repeat(30));
        console.log("Finish");
    } catch (ex) {
        console.error(ex);
    }
})().finally(() => {
    process.exit();
});

function extractUrls(conv) {
    const urls = [];
    const extract = (content) => {
        // <a href="{group1: url}">
        const urlArr = [...content.matchAll(/<a href="(.+?)">/gi)].map(
            (result) => result[1]
        );

        // Flat the urlArr when there is only one url
        if (urlArr.length === 1) {
            urls.push(urlArr[0]);
        } else if (urlArr.length > 1) {
            urls.push(urlArr);
        }
    };

    const editedMsgs = {};
    const msgs = conv.MessageList.filter(
        (msg) =>
            msg.messagetype &&
            msg.messagetype === "RichText" &&
            msg.content &&
            msg.content.includes("</a>")
    );

    for (const msg of msgs) {
        // <e_m ... ts="{group1: edit serial}" ...>
        const editedMsgMatch = msg.content.match(/<e_m.+?ts="([\d]+)".+?>/i);
        if (editedMsgMatch && editedMsgMatch[1]) {
            // Compare arrival time between messages with same edit serial then store the latest one
            if (
                !editedMsgs[editedMsgMatch[1]] ||
                msg.originalarrivaltime <=
                    editedMsgs[editedMsgMatch[1]].originalarrivaltime
            ) {
                editedMsgs[editedMsgMatch[1]] = msg;
            }
        } else {
            extract(msg.content);
        }
    }

    // Extract edited messages
    Object.values(editedMsgs).map((msg) => {
        extract(msg.content);
    });

    return urls;
}

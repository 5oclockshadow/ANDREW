let tokens = 0;\nfunction startChallenge() {\n    // Logic to start a challenge\n    console.log("Challenge started!");\n} \nfunction completeChallenge(reward) {\n    tokens += reward;\n    updateTokenDisplay();
    console.log(`Challenge completed! You earned ${reward} tokens.`);\n} \nfunction displayTokens() {\n    console.log(`Total tokens: ${tokens}`);\n}
function updateTokenDisplay() {\n    document.getElementById("tokenCount").innerText = tokens;\n}
startChallenge();\ncompleteChallenge(10);\ndisplayTokens();

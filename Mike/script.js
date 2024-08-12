// JavaScript to handle sign-up form link
document.getElementById('signUpBtn').addEventListener('click', function() {
    // Redirect to the sign-up form page
    window.location.href = 'signup.html';
});

// Optional: Handle QR code click if needed
document.getElementById('qrCodeImage').addEventListener('click', function() {
    // Action to perform when QR code is clicked
    alert('QR Code clicked! You can perform additional actions here.');
});

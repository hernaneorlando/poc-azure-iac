using Common.Models;
using Microsoft.AspNetCore.Mvc;

namespace Authentication.Resources;

[ApiController]
[Route("api/[controller]")]
public class AuthController(ILogger<AuthController> logger) : ControllerBase
{
    private static readonly List<LoginRequest> users =
    [
        new LoginRequest {Username = "root", Password = "root123"},
        new LoginRequest {Username = "admin", Password = "admin123"},
        new LoginRequest {Username = "tester", Password = "test123"},
    ];

    [HttpPost("login")]
    public IActionResult Login([FromBody] LoginRequest request)
    {
        var user = users.FirstOrDefault(u => u.Username == request.Username && u.Password == request.Password);
        if (user == null)
        {
            logger.LogWarning("Failed login attempt for user: {Username}", request.Username);
            return Unauthorized(new ApiResponse { Success = false, Message = "Invalid credentials" });
        }

        return Ok(new ApiResponse { Success = true, Data = new RefreshTokenRequest { Token = "SOME_JWT_TOKEN" } });
    }

    [HttpPost("refresh-token")]
    public IActionResult RefreshToken([FromBody] RefreshTokenRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Token))
        {
            logger.LogWarning("Invalid token refresh attempt");
            return BadRequest(new ApiResponse { Success = false, Message = "Invalid token" });
        }

        return Ok(new ApiResponse { Success = true, Data = new RefreshTokenRequest { Token = "NEW_JWT_TOKEN" } });
    }
}

public record LoginRequest
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}

public record RefreshTokenRequest
{
    public string Token { get; set; } = string.Empty;
}